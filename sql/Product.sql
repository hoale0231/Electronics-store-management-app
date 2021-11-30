use db_a2
go

EXEC sys.sp_addmessage  
	@msgnum   = 51000  
	,@severity = 16  
	,@msgtext  = N'Insert only one product at a time' 
	,@lang = 'us_english'
	,@replace = 'REPLACE'
go

EXEC sys.sp_addmessage  
	@msgnum   = 51001 
	,@severity = 16  
	,@msgtext  = N'Price much larger 1.2 PriceIn' 
	,@lang = 'us_english'
	,@replace = 'REPLACE'
go

EXEC sys.sp_addmessage  
	@msgnum   = 52000 
	,@severity = 16  
	,@msgtext  = N'%s is not valid!' 
	,@lang = 'us_english'
	,@replace = 'REPLACE'
go

-- Cau 4
-- function 1
create or alter function getValidSanPhamID(@ProdType nvarchar(100), @DeviceType nvarchar(100) = 'Other')
returns char(9)
as 
begin
	declare @id varchar(9);
	-- set product type code
	if @ProdType = 'Device'
		set @id = 'TB';
	else if @ProdType = 'Accessory'
		set @id = 'PK';
	else return '';
	-- set device type code
	declare @existsID table(ID char(9));
	if @DeviceType = 'Laptop'
		begin
			set @id = @id + 'LT';
			insert into @existsID select ID from Laptop;
		end
	else if @DeviceType = 'Phone'
		begin
			set @id = @id + 'DT';
			insert into @existsID select ID from DienThoai;
		end
	else if @DeviceType = 'Tablet'
		begin
			set @id = @id + 'MB';
			insert into @existsID select ID from MayTinhBang;
		end
	else if @DeviceType = 'Mouse'
		begin
			set @id = @id + 'CH';
			insert into @existsID select ID from Chuot;
		end
	else if @DeviceType = 'Headphone'
		begin
			set @id = @id + 'TN';
			insert into @existsID select ID from TaiNghe;
		end
	else 
		begin
			set @id = @id + 'KH';
			if @ProdType = 'Device'
				insert into @existsID select ID from ThietBiDienTu where left(ID,4) = 'TBKH';
			else if @ProdType = 'Accessory'
				insert into @existsID select ID from PhuKien where left(ID, 4) like 'PKKH';			
		end
	-- declare counter, cursor, currID for query
	declare @counter int;
	set @counter = 1;
	declare @currID char(9);
	declare IDCursor cursor
	for select ID from @existsID order by ID;
	open IDcursor;
	fetch next from IDCursor into @currID;
	while @@FETCH_STATUS = 0
	begin
		if @currID != @id + right('00000' + cast(@counter as varchar(5)), 5)
			break;
		fetch next from IDCursor into @currID;
		set @counter = @counter + 1
	end
	close IDcursor;
	deallocate IDcursor;
	return @id + right('00000' + cast(@counter as varchar(5)), 5)
end;
go
-- example function 1
select dbo.getValidSanPhamID('Device', 'Laptop') as NEW_ID
select dbo.getValidSanPhamID('Accessory', 'HeadPhone') as NEW_ID
select * from SanPham
where ID = dbo.getValidSanPhamID('Device', 'Laptop')
go

-- function 2
create or alter function getCurrentPrice(@ID char(9))
returns int
as begin 
	declare @promoLevel int, @price int
	set @promoLevel = (select PromoLevel
						from CTKM_SanPham, SanPham_ApDung_CTKM
						where CTKM_SanPham.ID = SanPham_ApDung_CTKM.ID_Ad and SanPham_ApDung_CTKM.ID_Prod = @ID
								and getdate() < CTKM_SanPham.TimeEnd and getdate() > CTKM_SanPham.TimeStart)
	if @promoLevel is NULL
		set @promoLevel = 0
	return (1 - @promoLevel/100.0) * (select Price from SanPham where SanPham.ID = @ID)
end
go
-- example function 2
select ID, price, dbo.getCurrentPrice(ID) as currentPrice
from SanPham
where Price != dbo.getCurrentPrice(ID)
go

-- Cau 1 
-- procedure insert
create or alter procedure insertSanPham
		-- Sanpham
		@ID          CHAR(9)		= NULL,
		@ProdName    nvarchar(100),
		@PriceIn     INT,
		@Price       INT,
		@Insurance   INT			= NULL,
		@Other       nvarchar(100)	= NULL,
		@Manufacture nvarchar(100)	= NULL,
		@ProdType	 nvarchar(100),
		@Available   bit			= 1,
		-- ThietBiDienTu
		@Battery     nvarchar(100)	= NULL,
		@DateRelease DATE			= NULL,
		@Screen      nvarchar(100)	= NULL,
		@RAM         nvarchar(100)	= NULL,
		@DeviceType  nvarchar(100)  = 'Other',
		@CPU_Chip    nvarchar(100)	= NULL,
		@GPU         nvarchar(100)	= NULL,
		@HardDisk    nvarchar(100)	= NULL,
		@Camera		 nvarchar(100)	= NULL,
		@SIM         nvarchar(100)	= NULL,
		-- PhuKien
		@Connection	varchar(100)	= NULL,
		@DPI varchar(100)			= null,
		@HPhoneType varchar(100)	= null
as 
begin 
    set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		if @ID is NULL
			set @ID = dbo.getValidSanPhamID(@ProdType, @DeviceType);
		else if left(@ID, 4) != left(dbo.getValidSanPhamID(@ProdType, @DeviceType), 4)
			begin
				DECLARE @msg0 NVARCHAR(2048) = FORMATMESSAGE(52000, 'ID');  
				throw 52000, @msg0, 1;
			end 

		-- insert Sanpham
		insert into SanPham ( ID,   ProdName,  PriceIn,  Price, Insurance,  Other, ProdType, manufacture,  TotalQuantity,  Available) 
		values				( @ID, @ProdName, @PriceIn, @Price, @Insurance, @Other, @ProdType,  @manufacture, 0, @Available)

		if (@ProdType = 'Device')
			begin
				-- insert ThietBiDienTu
				insert into ThietBiDienTu	(  ID,  Battery,  DateRelease,  Screen,  RAM,  DeviceType ) 
				values						( @ID, @Battery, @DateRelease, @Screen, @RAM, @DeviceType )
				-- insert Laptop/Phone/Tablet
				if (@DeviceType = 'Laptop')
					begin
						insert into Laptop  (ID,   CPU,		  GPU,  HardDisk)
						values				(@ID, @CPU_Chip, @GPU, @HardDisk)
					end
				else if (@DeviceType = 'Phone')
					begin
						insert into DienThoai	( ID,  Chip,    Camera,  SIM,  InDisk)
						values					(@ID, @Camera, @Camera, @SIM, @HardDisk)
					end
				else if (@DeviceType = 'Tablet')
					begin 
						insert into MayTinhBang	( ID,  Chip,	  Camera,  InDisk)
						values					(@ID, @CPU_Chip, @Camera, @HardDisk)
					end
			end
		else if (@ProdType = 'Accessory')
			begin
				-- insert Phu Kien
				insert into PhuKien (ID,   Connection, AccsoryType)
				values				(@ID, @Connection, @DeviceType);
				-- insert Mouse/Headphone
				if (@DeviceType = 'Mouse')
					begin
						insert into Chuot (ID,   DPI)
						values			  (@ID, @DPI)
					end
				else if (@DeviceType= 'Headphone')
					begin
						insert into TaiNghe( ID, HPhoneType, Battery)
						values			   (@ID, @HPhoneType, @Battery)
					end
			end
		else 
			begin
				DECLARE @msg1 NVARCHAR(2048) = FORMATMESSAGE(52000, 'ID');  
				throw 52000, @msg1, 1;
			end 
		select @ID as ID
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
END;
go
-- example procedure insert
delete from SanPham where ProdName = 'test'
exec insertSanPham @ID = 'PKCH00008',  @ProdName = 'test',  @PriceIn = 1,  @Price = 2, @ProdType = 'Device', @DeviceType = 'Laptop'
exec insertSanPham @ID = 'TBLT00008',  @ProdName = 'test',  @PriceIn = 1,  @Price = 2, @ProdType = 'Device', @DeviceType = 'Laptop'
select * from SanPham where ID = 'test'
go

-- Cau 2
-- trigger 1
create or alter trigger delete_Sanpham on SanPham
instead of delete
as begin
	declare @ID char(9);
	declare deleteProductCursor cursor for select ID from deleted;
	open deleteProductCursor;

	fetch next from deleteProductCursor into @ID;
	while @@FETCH_STATUS = 0
	begin
		-- Set available = 0
		update SanPham set Available = 0 where ID = @ID;
		declare @Count int;
		-- Count orders contain this product
		select @Count = COUNT(*) 
		from SanPham_Thuoc_DonHang 
		where ID_Prod = @ID;
		-- If no order contain this order, delete it
		if @Count = 0 
			delete from SanPham where ID = @ID;

		fetch next from deleteProductCursor into @ID;
	end
	close deleteProductCursor;
	deallocate deleteProductCursor;
end
go
-- example trigger 1
delete from SanPham where ID = 'TBLT00008'
select * from SanPham where ID = 'TBLT00008'
go

delete from SanPham where ID = 'TBLT00008'
select * from SanPham where ID = 'TBLT00008'
go
-- trigger 2
create or alter trigger insert_SanPham on SanPham
after insert
as begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @price int, @priceIn int, @Insurance int, @ID char(9), @ProdType nvarchar(100), @ID_branch char(9);
		select @priceIn = PriceIn, @price = Price, @Insurance = Insurance, @ID = ID, @ProdType = ProdType from inserted;

		if 1 < (select Count(ID) from inserted)
			begin
				DECLARE @msg NVARCHAR(2048) = FORMATMESSAGE(51000);  
				throw 51000, @msg, 1;
			end 

		if left(@ID, 2) != left(dbo.getValidSanPhamID(@ProdType, 'Other'), 2)
				begin
					DECLARE @msg0 NVARCHAR(2048) = FORMATMESSAGE(52000, 'ID');  
					throw 52000, @msg0, 1;
				end
			
		if @Insurance < 0
			begin
				DECLARE @msg1 NVARCHAR(2048) = FORMATMESSAGE(52000, 'Insurance');  
				throw 52000, @msg1, 1;
			end

		if @price < @priceIn * 1.2
			begin
				DECLARE @msg2 NVARCHAR(2048) = FORMATMESSAGE(51001);  
				throw 51001, @msg2, 1;
			end

		declare branchCursor cursor for select ID from ChiNhanh
		open branchCursor;
		fetch next from branchCursor into @ID_branch;
		while @@FETCH_STATUS = 0
		begin
			insert into ChiNhanh_Ban_SanPham (ID_Branch, ID_Prod, Quantity)
			values (@ID_branch, @ID, 0)
			fetch next from branchCursor into @ID_branch;
		end
		close branchCursor;
		deallocate branchCursor;

	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
	end;
go
-- example trigger 2
exec insertSanPham @ID = 'TBLT00008',  @ProdName = 'test',  @PriceIn = 1,  @Price = 1, @ProdType = 'Device', @DeviceType = 'Laptop'
exec insertSanPham @ID = 'TBLT00008',  @ProdName = 'test',  @PriceIn = 1,  @Price = 2, @Insurance = -1, @ProdType = 'Device', @DeviceType = 'Laptop'
update SanPham set ID = 'PKLT00001' where ID = 'TBLT00001'
go

-- Cau 3
-- procedure 1
create or alter procedure getProductsOfType 
(@Type nvarchar(100) = 'All', @DESC int = 0, @orderBy varchar(100) = NULL, @qty bigint = 5, @offset int = 0)
as	begin
		declare @idType char(4);	
		set @idType = case @Type
						when 'Laptop' then 'TBLT'
						when 'Phone' then 'TBDT'
						when 'Tablet' then 'TBMB'
						when 'Mouse' then 'PKCH'
						when 'HeadPhone' then 'PKTN'
						when 'OtherDevice' then 'TBKH'
						when 'OtherAccessory' then 'PKKH'
					  end;
		if (@qty = -1) set @qty = 9223372036854775807;
		select top (@qty) * from 
		(select SanPham.ID as ID, ProdName, PriceIn, Price, dbo.getCurrentPrice(SanPham.ID) as CurrentPrice, Insurance, TotalQuantity 
		from SanPham
		where (@Type = 'All' or left(SanPham.ID, 4) = @idType) and Available = 1
		order by 
				case @DESC when 0 then
				case @orderBy
					when 'Price' then Price
					when 'PriceIn' then PriceIn
					when 'CurrPrice' then dbo.getCurrentPrice(SanPham.ID)
					when 'Insurance' then Insurance
					when 'TotalQuantity' then TotalQuantity
					else right(ID, 4)
				end end asc,
				case @DESC when 1 then
				case @orderBy
					when 'Price' then Price
					when 'PriceIn' then PriceIn
					when 'CurrPrice' then dbo.getCurrentPrice(SanPham.ID)
					when 'Insurance' then Insurance
					when 'TotalQuantity' then TotalQuantity
					else right(ID, 4)
				end end desc
		offset (@offset * @qty) rows) T
end
go
-- example procedure 1
exec getProductsOfType @Type = 'Mouse', @orderBy = 'TotalQuantity', @qty = -1
exec getProductsOfType @Type = 'HeadPhone', @orderBy = 'CurrPrice', @qty = 3, @offset = 2, @desc = 1
go
-- procedure 2
create or alter procedure getSummaryProduct (@ProdType nvarchar(100) = 'All') as
	select BranchName, DeviceType, SUM(Quantity) as TotalProduct
	from ChiNhanh_Ban_SanPham, SanPham, ChiNhanh, ThietBiDienTu
	where ChiNhanh.ID = ID_Branch and SanPham.ID = ID_Prod  and (ThietBiDienTu.ID = ID_Prod)
	group by ID_Branch, BranchName, ProdType, DeviceType
	having DeviceType = @ProdType or ProdType = @ProdType or @ProdType = 'All'
	union
	select BranchName, AccsoryType as DeviceType, SUM(Quantity) as TotalProduct
	from ChiNhanh_Ban_SanPham, SanPham, ChiNhanh, PhuKien
	where ChiNhanh.ID = ID_Branch and SanPham.ID = ID_Prod  and (PhuKien.ID = ID_Prod)
	group by ID_Branch, BranchName, ProdType, AccsoryType
	having AccsoryType = @ProdType or ProdType = @ProdType or @ProdType = 'All'
go
-- example procedure 2
exec getSummaryProduct @ProdType = 'Accessory'
go

-- Cau 5
-- extra trigger
create or alter trigger delete_DonHang on SanPham_Thuoc_DonHang
after delete
as	begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @ID_Prod char(9);
		select @ID_Prod = ID_Prod from deleted

		delete from SanPham
		where ID = @ID_Prod and Available = 0
	commit TRANSACTION;
	set nocount off;
	set xact_abort off;
	end;
go

create or alter trigger update_SanPham on SanPham
after update
as begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @price int, @priceIn int, @Insurance int, @ID char(9), @ProdType nvarchar(100);
		declare productCursor cursor for select PriceIn, Price, Insurance, ID, ProdType from inserted;
		open productCursor;
		fetch next from productCursor into @priceIn, @price, @Insurance, @ID, @ProdType;
		while @@FETCH_STATUS = 0
		begin
			if left(@ID, 2) != left(dbo.getValidSanPhamID(@ProdType, 'Other'), 2)
				begin
					DECLARE @msg0 NVARCHAR(2048) = FORMATMESSAGE(52000, 'ID');  
					throw 52000, @msg0, 1;
				end
			
			if @Insurance < 0
				begin
					DECLARE @msg1 NVARCHAR(2048) = FORMATMESSAGE(52000, 'Insurance');  
					throw 52000, @msg1, 1;
				end

			if @price < @priceIn * 1.2
				begin
					DECLARE @msg2 NVARCHAR(2048) = FORMATMESSAGE(51001);  
					throw 51001, @msg2, 1;
				end
			
			fetch next from productCursor into @priceIn, @price, @Insurance, @ID, @ProdType;
		end
		close productCursor;
		deallocate productCursor;
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
end;
go

create or alter trigger instead_insert_ChiNhanh_Ban_SanPham 
on ChiNhanh_Ban_SanPham
instead of insert as
begin 
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @ID_branch char(9), @ID_Prod char(9), @Quantity int;
		declare qtyCursor cursor for select ID_Branch, ID_Prod, Quantity from inserted;
		open qtyCursor;
		fetch next from qtyCursor into @ID_branch, @ID_Prod, @Quantity;
		while @@FETCH_STATUS = 0
		begin
			if exists (select * from ChiNhanh_Ban_SanPham where ID_Branch = @ID_branch and ID_Prod = @ID_Prod)
			begin
				update ChiNhanh_Ban_SanPham set Quantity += @Quantity where ID_Branch = @ID_branch and ID_Prod = @ID_Prod
			end
			else begin
				insert into ChiNhanh_Ban_SanPham (ID_Branch, ID_Prod, Quantity) values (@ID_branch, @ID_Prod, @Quantity)
			end
			fetch next from qtyCursor into @ID_branch, @ID_Prod, @Quantity;
		end
		close qtyCursor;
		deallocate qtyCursor;
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
end

go

create or alter trigger inset_update_delete_ChiNhanh_Ban_SanPham on ChiNhanh_Ban_SanPham
after insert, update, delete
as	begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @Qty int, @prodID char(9);
		-- on insert
		declare BranchProductCursor cursor for select ID_Prod, Quantity from inserted;
		open BranchProductCursor;
		fetch next from BranchProductCursor into @prodID, @Qty;
		while @@FETCH_STATUS = 0
		begin
			if @Qty < 0
				begin
					DECLARE @msg NVARCHAR(2048) = FORMATMESSAGE(52000, 'Quantity');  
					throw 52000, @msg, 1;
				end
			update SanPham
			set TotalQuantity = (select TotalQuantity from SanPham where ID = @prodID) + @Qty
			where ID = @prodID
			fetch next from BranchProductCursor into @prodID, @Qty;
		end
		close BranchProductCursor;
		deallocate BranchProductCursor;
		-- on delete
		declare BranchProductCursor cursor for select ID_Prod, Quantity from deleted;
		open BranchProductCursor;
		fetch next from BranchProductCursor into @prodID, @Qty;
		while @@FETCH_STATUS = 0
		begin
			update SanPham
			set TotalQuantity = (select TotalQuantity from SanPham where ID = @prodID) - @Qty
			where ID = @prodID
			fetch next from BranchProductCursor into @prodID, @Qty;
		end
		close BranchProductCursor;
		deallocate BranchProductCursor;
	commit TRANSACTION;
	set nocount off;
	set xact_abort off;
	end;
go

-- extra procedure
create or alter procedure getInfoProduct (@ID char(9))
as 
begin
	if left(@ID, 4) = 'TBLT'
		select * from SanPham P, ThietBiDienTu T, Laptop D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if left(@ID, 4) = 'TBDT'
		select * from SanPham P, ThietBiDienTu T, DienThoai D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if left(@ID, 4) = 'TBMB'
		select * from SanPham P, ThietBiDienTu T, MayTinhBang D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if left(@ID, 4) = 'PKCH'
		select * from SanPham P, PhuKien T, Chuot D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if left(@ID, 4) = 'PKTN'
		select * from SanPham P, PhuKien T, TaiNghe D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if left(@ID, 4) = 'TBKH'
		select * from SanPham P, ThietBiDienTu T
		where P.ID = @ID and T.ID = @ID
	else if left(@ID, 4) = 'PKKH'
		select * from SanPham P, PhuKien T
		where P.ID = @ID and T.ID = @ID
	else select * from SanPham P where P.ID = @ID
end
go

create or alter procedure getQuantityProductBranchs (@ID char(9)) as
	select ID, Quantity
	from ChiNhanh, ChiNhanh_Ban_SanPham
	where ID_Prod = @ID and ID_Branch = ID
go

create or alter procedure updateSanPham
		-- Sanpham
		@ID          CHAR(9),
		@ProdName    nvarchar(100),
		@PriceIn     INT,
		@Price       INT,
		@Insurance   INT			= NULL,
		@Other       nvarchar(100)	= NULL,
		@Manufacture nvarchar(100)	= NULL,
		@ProdType	 nvarchar(100),
		@Available   bit			= NULL,
		@TotalQuantity INT		    = NULL,
		-- ThietBiDienTu
		@Battery     nvarchar(100)	= NULL,
		@DateRelease DATE			= NULL,
		@Screen      nvarchar(100)	= NULL,
		@RAM         nvarchar(100)	= NULL,
		@DeviceType  nvarchar(100)	= NULL,
		@AccsoryType nvarchar(100)	= NULL,
		@CPU	     nvarchar(100)	= NULL,
		@Chip		 nvarchar(100)	= NULL,
		@GPU         nvarchar(100)	= NULL,
		@HardDisk    nvarchar(100)	= NULL,
		@Camera		 nvarchar(100)	= NULL,
		@SIM         nvarchar(100)	= NULL,
		@Indisk		 nvarchar(100)	= NULL,
		-- PhuKien
		@Connection	varchar(100)	= NULL,
		@DPI varchar(100)			= NULL,
		@HPhoneType varchar(100)	= NULL
as 
begin 
    set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		-- insert Sanpham
		update SanPham 
		set ProdName = @ProdName, PriceIn = @PriceIn,  Price = @Price, Insurance = @Insurance, Other = @Other, manufacture = @Manufacture
		where ID = @ID;

		update ThietBiDienTu
		set Battery = @Battery, Screen = @Screen, DateRelease = @DateRelease, Ram = @RAM
		where ID = @ID;

		update PhuKien
		set Connection = @Connection
		where ID = @ID;

		update Laptop
		set GPU = @GPU, CPU = @CPU, HardDisk = @HardDisk
		where ID = @ID

		update DienThoai
		set Chip = @Chip, Camera = @Camera, SIM = @SIM, InDisk = @Indisk
		where ID = @ID

		update MayTinhBang
		set Chip = @Chip, Camera = @Camera, InDisk = @Indisk
		where ID = @ID

		update Chuot
		set DPI = @DPI
		where ID = @ID

		update TaiNghe
		set HPhoneType = @HPhoneType
		where ID = @ID
		
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
END;
go
