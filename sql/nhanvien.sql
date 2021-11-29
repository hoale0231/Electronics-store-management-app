create or alter procedure insertNhanVien 
	@ID			char(9),
	@Username	nvarchar(100),
	@Passwd		nvarchar(100),
	@IdNum		nvarchar(100),
	@Phone		nvarchar(100),
	@Salary		int   ,
	@Bdate		date,
	@Fname		nvarchar(100),
	@Lname		nvarchar(100),
	@Email		nvarchar(100),
	@Addr		nvarchar(100)  = NULL,
	@ID_branch	char(9)		
as
begin
	set nocount on;
	set xact_abort on;
	begin try
	if exists (select * from NhanVien where @ID = ID) throw 50010, N'Mã nhân viên đã tồn tại.' ,1
	else if exists (select * from NhanVien where @Username = Username) throw 50010, N'Tên đăng nhập đã tồn tại.' ,1
	else if exists (select * from NhanVien where @Email = Email) throw 50010, N'Email đã tồn tại.' ,1
	else if (year(CAST( GETDATE() AS Date )) - year(@Bdate)) < 18 throw 50010, N'Nhân viên phải lớn hơn hoặc bằng 18 tuổi.' ,1
	else 
			insert into NhanVien (ID, Username, Passwd, IdNum, Phone, Salary, Bdate, Fname, Lname, Email, Addr, ID_branch)
			values (@ID, @Username, @Passwd, @IdNum, @Phone, @Salary, @Bdate, @Fname, @Lname, @Email, @Addr, @ID_branch)
	end try
	begin catch
		select ERROR_MESSAGE() as Error
	end catch
	set nocount off;
	set xact_abort off;
end
go
exec insertNhanVien '17', 'dangtu2009', 'tu123456', '212356385', '0331263556', 10000000, '12-07-2009', N'Nguyễn Đăng', N'Tú', 'tu1234@gmail.com', N'Mộ Đức, Quảng Ngãi', '3';
exec insertNhanVien '16', 'dangtu1996', 'tu123456', '212316385', '0331263856', 12000000, '12-07-2002', N'Nguyễn Đăng', N'Tú', 'tu1233@gmail.com', N'Mộ Đức, Quảng Ngãi', '3';
select * from NhanVien
go 

create or alter trigger salary_check
on NhanVien
after update 
as 
	begin 
		set nocount on;
		if cast((select salary from inserted) as int) > cast((select salary from deleted) as int )* 1.2
		begin 
			COMMIT TRANSACTION;
				RAISERROR (15600,-1,-1, N'lương mới không được lớn hơn 20% so với luơng củ');  
			ROLLBACK TRANSACTION;
		end 
		set nocount off;
	end

go

update NhanVien
set Salary = 25000000
where ID = 1

update NhanVien
set Salary = 26000000
where ID = 1

go

create or alter trigger delete_nt
on NhanVien
instead of delete
as 
	begin
		set nocount on;
			if exists (select * from ChiNhanh where ID_Manager = (select ID from deleted))
			update ChiNhanh set ID_Manager = null where ID_Manager = (select ID from deleted);
			update Donhang set ID_Employee = null where ID_Employee = (select ID from deleted);
			delete from NguoiThan where ID_Employee = (select ID from deleted);
			delete from NhanVien where ID = (select ID from deleted);
		set nocount off;
	end

go

delete from NhanVien where ID = 2;
delete from NhanVien where ID = 8;

go

create or alter procedure nhanvien_nguoithan
as
	begin
		select NhanVien.ID, NhanVien.Fname , NhanVien.Lname, NguoiThan.Fname, NguoiThan.Lname, NguoiThan.Relation
		from NhanVien, NguoiThan
		where NhanVien.ID = NguoiThan.ID_Employee 
		order by NhanVien.Fname
	end

go

exec nhanvien_nguoithan;

go

create or alter procedure chinhanh_slNV
		@sl int
as begin
		select ChiNhanh.BranchName, ChiNhanh.ID_Manager, COUNT(*) as quantityNV
		from ChiNhanh, NhanVien
		where ChiNhanh.ID = NhanVien.ID_branch
		group by ChiNhanh.BranchName, ChiNhanh.ID_Manager
		having COUNT(*) > @sl
		order by ChiNhanh.BranchName
	end

go

	exec chinhanh_slNV @sl = 3;
	exec chinhanh_slNV @sl = 1;

go
	create or alter function Nhanvien_chinhanh(@CNId char(9))
	returns @person table(
		firstName nvarchar(100),
		lastName nvarchar(100),
		addr nvarchar(100) 
	) 
	as 
	begin
		if @CNId = '0' return;
		insert into @person 
		select Fname, Lname, addr 
		from NhanVien
		where ID_branch = @CNId
		return;
	end
go
	select * from Nhanvien_chinhanh('2')
	select * from Nhanvien_chinhanh('3')
go
	create or alter function slnv_tuoi(@tuoi int)
	returns int 
	as
	begin 
	    declare @sl int
		if @tuoi < 18 return 0
		set @sl = (select count(*) from NhanVien where year(CAST( GETDATE() AS Date )) - year(Bdate) < @tuoi)
		return @sl
	end
go
	print dbo.slnv_tuoi(30);
	print dbo.slnv_tuoi(18);
go



select * from NhanVien;