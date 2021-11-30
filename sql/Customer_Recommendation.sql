use db_a2
go
-- Tables: KhachHang, GioiThieu
-- 1. Procedure to insert data to table
create or alter procedure Insert_KhachHang
	@id			char(9),
	@username	nvarchar(100),
	@passwd		nvarchar(100),
	@phone		nvarchar(100),
	@fname		nvarchar(100),
	@lname		nvarchar(100),
	@email		nvarchar(100) = null,
	@bdate		date		  = null,
	@idnum		nvarchar(100),
	@famscore	int			  = 0
as
begin
	-- validation
	if @id is null or @username is null or @passwd is null or 
		@phone is null or @fname is null or @lname is null or @idnum is null
	begin
		raiserror('some non-null values is null!', 16, 1);
		return;
	end;
	if exists (select * from KhachHang where ID=@id)
	begin
		raiserror('id existed!', 16, 1);
		return;
	end;
	if exists (select * from KhachHang where Username=@username)
	begin
		raiserror('username existed!', 16, 1);
		return;
	end;
	if len(@passwd) < 6
	begin
		raiserror('password is too short (<6 characters)!', 16, 1);
		return;
	end;
	if not (CHARINDEX(' ',LTRIM(RTRIM(@email))) = 0 
	AND  LEFT(LTRIM(@email),1) <> '@' 
	AND  RIGHT(RTRIM(@email),1) <> '.' 
	AND  CHARINDEX('.',@email ,CHARINDEX('@',@email)) - CHARINDEX('@',@email ) > 1 
	AND  LEN(LTRIM(RTRIM(@email ))) - LEN(REPLACE(LTRIM(RTRIM(@email)),'@','')) = 1 
	AND  CHARINDEX('.',REVERSE(LTRIM(RTRIM(@email)))) >= 3 
	AND  (CHARINDEX('.@',@email ) = 0 AND CHARINDEX('..',@email ) = 0))
	begin
		raiserror('wrong email format!', 16, 1);
		return;
	end;
	if @bdate is not null and datediff(year, @bdate, getdate()) < 18
	begin
		raiserror('user must older than 18 years!', 16, 1);
		return;
	end;
	insert into KhachHang(ID, Username, Passwd, Phone, Fname, Lname, Email, Bdate, IdNum, FamScore)
		values (@id, @username, @passwd, @phone, @fname, @lname, @email, @bdate, @idnum, @famscore)
end;
go

exec Insert_KhachHang '15', 'tuan01', 'tuantuan', '0123456789', 'Trinh', 'Tuan', 'tuan@example.com', '2001-01-01', '2123456789'
go
exec Insert_KhachHang '16', 'mmt211', 'tuantuan', '0123456789', 'Trinh', 'Tuan', 'tuan@example.com', '2001-01-01', '2123456789'
go
exec Insert_KhachHang '16', 'tuan01', 'tuan', '0123456789', 'Trinh', 'Tuan', 'tuan@example.com', '2001-01-01', '2123456789'
go
exec Insert_KhachHang '16', 'tuan01', 'tuantuan', '0123456789', 'Trinh', 'Tuan', 'tuan@@example.com', '2001-01-01', '2123456789'
go
exec Insert_KhachHang '16', 'tuan01', 'tuantuan', '0123456789', 'Trinh', 'Tuan', 'tuan@example.com', '2010-01-01', '2123456789'
go

create or alter procedure Insert_GioiThieu
	@idref char(9),
	@id char(9)
as
begin
	if @id is null or @idref is null
	begin
		raiserror('some non-null values is null!', 16, 1);
		return;
	end;
	insert into GioiThieu(IDRef, ID) values (@idref, @id);
end;
go

-- 2. Trigger to control INSERT, UPDATE, DELETE in tables
-- Trigger to check if FamScore of KhachHang is positive
create or alter trigger check_famScore
on KhachHang
for insert, update
as
begin
	declare @famScore int;
	declare famScoreCursor cursor for select FamScore from inserted;
	open famScoreCursor;
	fetch next from famScoreCursor into @famScore;
	while @@FETCH_STATUS = 0
	begin
		if (@famScore < 0)
		begin
			raiserror('FamScore must be positive', 16, 1);
			rollback;
		end;
		fetch next from famScoreCursor into @famScore;
	end;
	close famScoreCursor;
	deallocate famScoreCursor;
end;
go

exec Insert_KhachHang '16', 'tuan01', 'tuantuan', '0123456789', 'Trinh', 'Tuan', 'tuan@example.com', '2001-01-01', '2123456789', -1
go

-- Trigger to update FamScore of KhachHang when GioiThieu is changed.
-- For each person, they receive 100 in FamScore for each person they reference.
create or alter trigger update_famScore
on GioiThieu
for insert, update, delete
as
begin
	-- on insert
	declare @idref_ins char(9);
	declare insertCursor cursor for select IDRef from inserted;

	open insertCursor;
	fetch next from insertCursor into @idref_ins;
	while @@FETCH_STATUS = 0
	begin
		update KhachHang
		set FamScore += 100
		where ID = @idref_ins
		fetch next from insertCursor into @idref_ins;
	end;

	close insertCursor;
	deallocate insertCursor;

	-- on delete
	declare @idref_del char(9);
	declare deleteCursor cursor for select IDRef from deleted;

	open deleteCursor;
	fetch next from deleteCursor into @idref_del;
	while @@FETCH_STATUS = 0
	begin
		-- if FamScore of KhachHang is >= then decrease it by 100.
		update KhachHang
		set FamScore -= 100
		where ID = @idref_del and FamScore >= 100;
		-- else set FamScore to 0.
		update KhachHang
		set FamScore = 0
		where ID = @idref_del and FamScore < 100;
	end;

	close deleteCursor;
	deallocate deleteCursor;
end;
go

-- Examples: Consider we care about ID=8 and ID=10.
create or alter procedure print_FamScore_ID_8_10
as
begin
	select ID, FamScore from KhachHang where ID = 8 or ID = 10;
end;
go

-- There is a line {IDRef=8, ID=14) in GioiThieu.
exec print_FamScore_ID_8_10;
-- Expected:
-- ID=8, FamScore=5000     
-- ID=10, FamScore=0
-- Change IDRef of this line to 10
update GioiThieu
set IDRef = 10
where IDRef=8 and ID=14;
exec print_FamScore_ID_8_10;
-- Expected:
-- ID=8, FamScore=4900     
-- ID=10, FamScore=100
go
-- Set back IDRef of this line to 8
update GioiThieu
set IDRef=8
where IDRef=10 and ID=14;
exec print_FamScore_ID_8_10;
-- Expected:
-- ID=8, FamScore=5000     
-- ID=10, FamScore=0
go

-- 3. Procedure to select data
-- Procecdure to get list of KhachHang that @idref recommending (contains where, order by)
create or alter procedure get_list_recommendee
	@idref char(9)
as
begin
	select *
	from KhachHang
	where ID in
		(select ID
		from GioiThieu
		where IDRef=@idref)
	order by Lname;
end;
go

exec get_list_recommendee '8';
go

-- Procedure to get list of KhachHang that recommends at least @min_ref person (aggreate function, group by, having, where and order by)
create or alter procedure get_list_recommender
	@min_ref int
as
begin
	select *
	from KhachHang,
		(select IDRef, count(*) as Num_ref
		from GioiThieu
		group by IDRef
		having count(*) >= @min_ref) as Count_ref
	where KhachHang.ID = Count_ref.IDRef
	order by Count_ref.Num_ref desc;
end;
go

exec get_list_recommender 1;
go
exec get_list_recommender 2;
go

-- 4. Functions
-- Function to get average FamScore of KhachHang where their ages in [@age_start, @age_end]
-- Return -1 if error and return -2 if not found KhachHang specified.
create or alter function get_avg_FamScore (
	@age_start int,
	@age_end int
)
returns int
as
begin
	-- validation
	if (@age_start < 18 or @age_end < 18)
		return -1;
	if (@age_start > @age_end)
		return -1;
	-- select query
	declare @KhachHang_agetrim table (ID char(9) not null, FamScore int);
	insert into @KhachHang_agetrim
		select ID, FamScore
		from KhachHang 
		where Bdate is not null and @age_start <= datediff(year, Bdate, getdate()) 
			and datediff(year, Bdate, getdate()) <= @age_end;
	update @KhachHang_agetrim
	set FamScore=0
	where FamScore=null;
	-- calculation
	declare @avg_famScore int = -2;
	declare @count_agetrim int;
	select @count_agetrim= count(*) from @KhachHang_agetrim;
	if (@count_agetrim > 0)
		select @avg_famScore = cast(avg(FamScore) as int) from @KhachHang_agetrim;
	return @avg_famScore;
end;
go

print dbo.get_avg_FamScore(18, 19);
print dbo.get_avg_FamScore(20, 20);
go

-- Function to get average people that each KhachHang recommends where their age in [@age_start, @age_end]
-- Return -1 if error and return -2 if not found KhachHang specified.
create or alter function get_avg_recommendee (
	@age_start int,
	@age_end int
)
returns int
as
begin
	-- validation
	if (@age_start < 18 or @age_end < 18)
		return -1;
	if (@age_start > @age_end)
		return -1;
	-- select query
	declare @KhachHang_filter table (ID char(9));
	declare @KhachHang_ref table (ID char(9) not null, Num_ref int);
	insert into @KhachHang_filter
		select ID
		from KhachHang
		where Bdate is not null and @age_start <= datediff(year, Bdate, getdate()) 
			and datediff(year, Bdate, getdate()) <= @age_end;
	if ((select count(*) from @KhachHang_filter) = 0)
		return -2;

	insert into @KhachHang_ref
		select IDRef, count(*) as Num_ref
		from GioiThieu
		where IDRef in (select * from @KhachHang_filter)
		group by IDRef;

	insert into @KhachHang_ref
		select ID, 0
		from KhachHang
		where ID in (select * from @KhachHang_filter) and ID not in (select ID from @KhachHang_ref);

	-- calculation
	declare @avg_ref int;
	select @avg_ref = cast(avg(Num_ref) as int) from @KhachHang_ref;
	return @avg_ref;
end;
go

print dbo.get_avg_recommendee(23, 23);
go

-- Select using functions
-- Some functions to return tables
create or alter function get_list_FamScore (
	@age_start int,
	@age_end int
)
returns @list_famScore table (
	ID char(9) not null, 
	FamScore int
	)
as
begin
	-- validation
	if (@age_start < 18 or @age_end < 18)
		return;
	if (@age_start > @age_end)
		return;
	-- select query
	insert into @list_famScore
		select ID, FamScore
		from KhachHang 
		where Bdate is not null and @age_start <= datediff(year, Bdate, getdate()) 
			and datediff(year, Bdate, getdate()) <= @age_end;
	update @list_famScore
	set FamScore=0
	where FamScore=null;
	return;
end;
go

create or alter function get_list_num_recommendee(
	@age_start int,
	@age_end int
)
returns @list_numref table(
	ID char(9) not null,
	Num_recommendee int
	)
as
begin
	-- validation
	if (@age_start < 18 or @age_end < 18)
		return;
	if (@age_start > @age_end)
		return;
	-- select query
	declare @KhachHang_filter table (ID char(9));
	insert into @KhachHang_filter
		select ID
		from KhachHang
		where Bdate is not null and @age_start <= datediff(year, Bdate, getdate()) 
			and datediff(year, Bdate, getdate()) <= @age_end;
	if ((select count(*) from @KhachHang_filter) = 0)
		return;

	insert into @list_numref
		select IDRef, count(*) as Num_ref
		from GioiThieu
		where IDRef in (select * from @KhachHang_filter)
		group by IDRef;

	insert into @list_numref
		select ID, 0
		from KhachHang
		where ID in (select * from @KhachHang_filter) and ID not in (select ID from @list_numref);

	return;
end;
go

-- Select list of ID of all customers in the age from 23 to 25 with FamScore above average
select * from get_list_FamScore(23, 25);
go
select dbo.get_avg_FamScore(23, 25) as Average_FamScore;
go
select * from get_list_FamScore(23, 25)
where FamScore > dbo.get_avg_FamScore(23, 25);
go

-- Select list of ID of all customers in the age of 23 that recommend more than average people.
select * from get_list_num_recommendee(23, 23);
go
select dbo.get_avg_recommendee(23, 23) as Average_Recommendee;
go
select * from get_list_num_recommendee(23, 23)
where Num_recommendee > dbo.get_avg_recommendee(23, 23);
go
