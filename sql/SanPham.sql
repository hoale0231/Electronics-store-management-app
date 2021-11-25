use db_a2
go
use company
EXEC sys.sp_addmessage  
	@msgnum   = 51000  
	,@severity = 16  
	,@msgtext  = N'Product type much be Device or Accessory' 
	,@lang = 'us_english';  
go;

EXEC sys.sp_addmessage  
	@msgnum   = 51001 
	,@severity = 16  
	,@msgtext  = N'Price much larger 1.2 PriceIn' 
	,@lang = 'us_english';  
go;

EXEC sys.sp_addmessage  
	@msgnum   = 52000 
	,@severity = 16  
	,@msgtext  = N'%s is not valid!' 
	,@lang = 'us_english';  
go;

-- Câu 4

create or alter function getValidSanPhamID(@ProdType nvarchar(100), @DeviceType nvarchar(100))
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
				insert into @existsID select ID from ThietBiDienTu where ID like '[T][B][K][H]%';
			else if @ProdType = 'Accessory'
				insert into @existsID select ID from ThietBiDienTu where ID like '[P][K][K][H]%';			
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

select * from SanPham
select dbo.getValidSanPhamID('Device', 'Laptop') as NEW_ID
select dbo.getValidSanPhamID('Device', 'Phone') as NEW_ID
select * from SanPham
where ID = dbo.getValidSanPhamID('Device', 'Laptop')
go

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

select ID, price, dbo.getCurrentPrice(ID) as currentPrice
from SanPham
where Price != dbo.getCurrentPrice(ID)
go
-- Câu 1 
create or alter procedure insertSanPham
		-- Sanpham
		@ID          CHAR(9)		= NULL,
		@ProdName    nvarchar(100),
		@PriceIn     INT			= NULL,
		@Price       INT			= NULL,
		@Insurance   INT			= NULL,
		@Other       nvarchar(100),
		@Manufacture nvarchar(100),
		@ProdType	 nvarchar(100),
		-- ThietBiDienTu
		@Battery     nvarchar(100)	= NULL,
		@DateRelease DATE			= NULL,
		@Screen      nvarchar(100)	= NULL,
		@RAM         nvarchar(100)	= NULL,
		@DeviceType  nvarchar(100),
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

		if @Price < @PriceIn * 1.2
			begin
				DECLARE @msg1 NVARCHAR(2048) = FORMATMESSAGE(51001);  
				throw 51001, @msg1, 1;
			end
		-- insert Sanpham
		insert into SanPham ( ID,   ProdName,  PriceIn,  Price, Insurance,  Other, ProdType, manufacture,  TotalQuantity) 
		values				( @ID, @ProdName, @PriceIn, @Price, @Insurance, @Other, @ProdType,  @manufacture, 0)

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
				DECLARE @msg2 NVARCHAR(2048) = FORMATMESSAGE(51000);  
				throw 51000, @msg2, 1;
			end
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
END;
go

delete from SanPham where ID = 'TBLT00007'
exec insertSanPham @ID = 'TBLT00007',  @ProdName = 'GIGABYTE Gaming G5',  @PriceIn = 22500000,  @Price = 28000000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Gigabyte',   @ProdType = 'Device', @Battery = '4-cell, 41Wh',  @DateRelease = '01-01-2021',  @Screen = '15.6", Full HD (1920 x 1080), 144Hz', @RAM = '16 GBDDR4 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'i510500H2.5GHz',  @GPU = 'RTX 3060 6GB',  @HardDisk = '512 GB SSD NVMe PCIe' 
exec insertSanPham @ID = 'TBDT00007',  @ProdName = 'GIGABYTE Gaming G5',  @PriceIn = 22500000,  @Price = 28000000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Gigabyte',   @ProdType = 'Device', @Battery = '4-cell, 41Wh',  @DateRelease = '01-01-2021',  @Screen = '15.6", Full HD (1920 x 1080), 144Hz', @RAM = '16 GBDDR4 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'i510500H2.5GHz',  @GPU = 'RTX 3060 6GB',  @HardDisk = '512 GB SSD NVMe PCIe' 
go

-- Câu 2
create or alter trigger update_price on SanPham
after insert, update
as begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @price int, @priceIn int;
		declare priceCursor cursor for select PriceIn, Price from inserted;
		open priceCursor;
		fetch next from priceCursor into @priceIn, @price;
		while @@FETCH_STATUS = 0
		begin
			if @price < @priceIn * 1.2
				begin
					DECLARE @msg NVARCHAR(2048) = FORMATMESSAGE(51001);  
					throw 51001, @msg, 1;
				end
			
			fetch next from priceCursor into @priceIn, @price;
		end
		close priceCursor;
		deallocate priceCursor;
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
	end;
go

update SanPham
set price = 2, PriceIn = 2
where ID = 'TBLT00001'
go

create or alter trigger update_totalQuantity on ChiNhanh_Ban_SanPham
after insert, update, delete
as	begin
	set nocount on;
	set xact_abort on;
	BEGIN TRANSACTION;
		declare @Qty int, @prodID char(9);
		-- on insert
		declare productCursor cursor for select ID_Prod, Quantity from inserted;
		open productCursor;
		fetch next from productCursor into @prodID, @Qty;
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
			fetch next from productCursor into @prodID, @Qty;
		end
		close productCursor;
		deallocate productCursor;
		-- on delete
		declare productCursor cursor for select ID_Prod, Quantity from deleted;
		open productCursor;
		fetch next from productCursor into @prodID, @Qty;
		while @@FETCH_STATUS = 0
		begin
			update SanPham
			set TotalQuantity = (select TotalQuantity from SanPham where ID = @prodID) - @Qty
			where ID = @prodID
			fetch next from productCursor into @prodID, @Qty;
		end
		close productCursor;
		deallocate productCursor;
	commit TRANSACTION;
	set nocount off;
	set xact_abort off;
	end;
go

-- Câu 3
create or alter procedure getInfoProduct (@ID char(9))
as 
begin
	if @ID like '[T][B][L][T]%'
		select * from SanPham P, ThietBiDienTu T, Laptop D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if @ID like '[T][B][D][T]%'
		select * from SanPham P, ThietBiDienTu T, DienThoai D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if @ID like '[T][B][M][B]%'
		select * from SanPham P, ThietBiDienTu T, MayTinhBang D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if @ID like '[P][K][C][H]%'
		select * from SanPham P, PhuKien T, Chuot D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if @ID like '[P][K][T][N]%'
		select * from SanPham P, PhuKien T, TaiNghe D
		where P.ID = @ID and T.ID = @ID and D.ID = @ID
	else if @ID like '[T][B][K][H]%'
		select * from SanPham P, ThietBiDienTu T
		where P.ID = @ID and T.ID = @ID
	else if @ID like '[P][K][K][H]%'
		select * from SanPham P, PhuKien T
		where P.ID = @ID and T.ID = @ID
	else select * from SanPham P where P.ID = @ID
end
go

exec getInfoProduct @ID = 'TBMB00001' 
go

create or alter procedure getProductsOfType 
(@Type nvarchar(100), @DESC int = 0, @orderBy varchar(100), @qty int = 5, @offset int = 0)
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

		select top (@qty) * from 
		(select SanPham.ID as ID, ProdName, PriceIn, Price, dbo.getCurrentPrice(SanPham.ID) as CurrentPrice, Insurance, TotalQuantity 
		from SanPham
		where left(SanPham.ID, 4) = @idType
		order by 
				case @DESC when 0 then
				case @orderBy
					when 'Price' then Price
					when 'PriceIn' then PriceIn
					when 'CurrPrice' then dbo.getCurrentPrice(SanPham.ID)
					when 'Insurance' then Insurance
					when 'TotalQuantity' then TotalQuantity
					else ID
				end end asc,
				case @DESC when 1 then
				case @orderBy
					when 'Price' then Price
					when 'PriceIn' then PriceIn
					when 'CurrPrice' then dbo.getCurrentPrice(SanPham.ID)
					when 'Insurance' then Insurance
					when 'TotalQuantity' then TotalQuantity
					else ID
				end end desc
		offset (@offset * @qty) rows) T
end
go

exec getProductsOfType @Type = 'Mouse', @orderBy = 'CurrPrice'
exec getProductsOfType @Type = 'Mouse', @orderBy = 'CurrPrice', @offset = 1
exec getProductsOfType @Type = 'HeadPhone', @orderBy = 'Insurance', @qty = 2, @desc = 1
exec getProductsOfType @Type = 'HeadPhone', @orderBy = 'Insurance', @qty = 2, @offset = 4, @desc = 1
go

create or alter procedure getSummaryProduct (@ProdType nvarchar(100) = NULL) as
	select BranchName, DeviceType, SUM(Quantity) as TotalProduct
	from ChiNhanh_Ban_SanPham, SanPham, ChiNhanh, ThietBiDienTu
	where ChiNhanh.ID = ID_Branch and SanPham.ID = ID_Prod  and (ThietBiDienTu.ID = ID_Prod)
	group by ID_Branch, BranchName, ProdType, DeviceType
	having DeviceType = @ProdType or ProdType = @ProdType or @ProdType is NULL
	union
	select BranchName, AccsoryType as DeviceType, SUM(Quantity) as TotalProduct
	from ChiNhanh_Ban_SanPham, SanPham, ChiNhanh, PhuKien
	where ChiNhanh.ID = ID_Branch and SanPham.ID = ID_Prod  and (PhuKien.ID = ID_Prod)
	group by ID_Branch, BranchName, ProdType, AccsoryType
	having AccsoryType = @ProdType or ProdType = @ProdType or @ProdType is NULL
go

exec getSummaryProduct @ProdType = 'Accessory'
