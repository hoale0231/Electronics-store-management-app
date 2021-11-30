use db_a2
go

-- Insert SanPham
create or alter procedure insertSanPham
		-- Sanpham
		@ID          CHAR(9),
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
		-- insert Sanpham
		insert into SanPham ( ID,   ProdName,  PriceIn,  Price, Insurance,  Other, ProdType, manufacture,  TotalQuantity, Available) 
		values				( @ID, @ProdName, @PriceIn, @Price, @Insurance, @Other, @ProdType,  @manufacture, 0, 1)
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
	COMMIT TRANSACTION;
	set nocount off;
	set xact_abort off;
END;
go

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


-- insert Laptop
exec insertSanPham @ID = 'TBLT00001',  @ProdName = 'Acer Nitro 5 Gaming AN515',  @PriceIn = 23000000,  @Price = 29690000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Acer',   @ProdType = 'Device', @Battery = '4-cell, 57Wh',  @DateRelease = '01-01-2021',  @Screen = '15.6", FullHD (1920 x 1080), 144Hz', @RAM = '8 GBDDR4 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'i711800H2.30 GHz',  @GPU = 'RTX 3050Ti 4GB',  @HardDisk = '512 GB SSD NVMe PCIe'
exec insertSanPham @ID = 'TBLT00002',  @ProdName = 'Lenovo Ideapad 5 Pro',  @PriceIn = 19000000,  @Price = 24000000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Lenovo',   @ProdType = 'Device', @Battery = '56.5Wh',  @DateRelease = '01-01-2021',  @Screen = '14", 2.2K (2240x1400)', @RAM = '8 GBDDR4 (On board) 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'i51135G72.4GHz',  @GPU = 'MX450 2GB',  @HardDisk = '512 GB SSD NVMe PCIe' 
exec insertSanPham @ID = 'TBLT00004',  @ProdName = 'Asus ROG Zephyrus G14',  @PriceIn = 35500000,  @Price = 44990000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Asus',   @ProdType = 'Device', @Battery = '4-cell, 76Wh',  @DateRelease = '01-01-2021',  @Screen = '14", QHD (2560 x 1440), 120Hz', @RAM = '16 GBDDR4 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'Ryzen 95900HS3GHz',  @GPU = 'RTX 3050Ti 4GB',  @HardDisk = '1 TB SSD M.2 PCIe 3.0'
exec insertSanPham @ID = 'TBLT00005',  @ProdName = 'MacBook Pro 2020',  @PriceIn = 35000000,  @Price = 42500000,  @Insurance = 18,  @Other = 'LED keyboard',  @Manufacture = 'Apple',   @ProdType = 'Device', @Battery = '10 hours' ,  @DateRelease = '01-01-2020',  @Screen = '13.3", Retina (2560 x 1600)', @RAM = '16 GB',  @DeviceType = 'Laptop',  @CPU_Chip = 'Apple M1',  @GPU = 'integrated card, 8 core GPU',  @HardDisk = '512 GB SSD'
exec insertSanPham @ID = 'TBLT00007',  @ProdName = 'GIGABYTE Gaming G5',  @PriceIn = 22500000,  @Price = 28000000,  @Insurance = 12,  @Other = 'LED keyboard',  @Manufacture = 'Gigabyte',   @ProdType = 'Device', @Battery = '4-cell, 41Wh',  @DateRelease = '01-01-2021',  @Screen = '15.6", Full HD (1920 x 1080), 144Hz', @RAM = '16 GBDDR4 3200 MHz',  @DeviceType = 'Laptop',  @CPU_Chip = 'i510500H2.5GHz',  @GPU = 'RTX 3060 6GB',  @HardDisk = '512 GB SSD NVMe PCIe' 
-- Insert DienThoai
exec insertSanPham @ID = 'TBDT00001',  @ProdName = 'Samsung Galaxy Z Fold3',  @PriceIn = 18000000,  @Price = 22990000,  @Insurance = 12,  @Other = NULL,  @Manufacture = 'Samsung',   @ProdType = 'Device', @Battery = '4400 mAh, 25 W',  @DateRelease = '01-01-2021',  @Screen = 'Dynamic AMOLED 2X Full HD+', @RAM = '12 GB',  @DeviceType = 'Phone',  @CPU_Chip = 'Snapdragon 888',  @Camera = '10 MP & 4 MP',  @HardDisk = '512 GB', @SIM = '2 Nano SIM + 1 eSIM, 5G'    
exec insertSanPham @ID = 'TBDT00002',  @ProdName = 'iPhone 12 64GB',  @PriceIn = 15000000,  @Price = 20990000,   @Insurance = 12,  @Other = NULL,  @Manufacture = 'Apple',   @ProdType = 'Device', @Battery = '2815 mAh, 20 W',  @DateRelease = '01-01-2020',  @Screen = 'OLED6.1" Super Retina XDR', @RAM = '4 GB',  @DeviceType = 'Phone',  @CPU_Chip = 'Apple A14 Bionic',  @Camera = '12 MP',  @HardDisk = '64 GB', @SIM = '1 Nano SIM & 1 eSIM, 5G'    
exec insertSanPham @ID = 'TBDT00003',  @ProdName = 'Xiaomi 11T 5G 128GB',  @PriceIn = 8000000,  @Price = 11990000,  @Insurance = 12,  @Other = NULL,  @Manufacture = 'Xiaomi',   @ProdType = 'Device', @Battery = '5000 mAh, 67 W',  @DateRelease = '01-01-2021',  @Screen = 'AMOLED6.67" Full HD+', @RAM = '8 GB',  @DeviceType = 'Phone',  @CPU_Chip = 'MediaTek Dimensity 1200',  @Camera = '16 MP',  @HardDisk = '128 GB', @SIM = '2 Nano SIM, 5G'             
exec insertSanPham @ID = 'TBDT00004',  @ProdName = 'Samsung Galaxy A03s',  @PriceIn = 25000000,  @Price = 36900000,  @Insurance = 12,  @Other = NULL,  @Manufacture = 'Samsung',   @ProdType = 'Device', @Battery = '5000 mAh, 7.75 W',  @DateRelease = '01-01-2020',  @Screen = 'PLS LCD6.5" HD+', @RAM = '4 GB',  @DeviceType = 'Phone',  @CPU_Chip = 'MediaTek MT6765',  @Camera = '5 MP',  @HardDisk = '64 GB', @SIM = '2 Nano SI 4G'               
exec insertSanPham @ID = 'TBDT00005',  @ProdName = 'Samsung Galaxy A52s 5G',  @PriceIn = 7000000,  @Price = 10990000,  @Insurance = 12,  @Other = NULL,  @Manufacture = 'Samsung',   @ProdType = 'Device', @Battery = '4500 mAh, 25 W',  @DateRelease = '01-01-2020',  @Screen = 'Super AMOLED6.5" Full HD+', @RAM = '8 GB',  @DeviceType = 'Phone',  @CPU_Chip = 'Snapdragon 778G 5G 8 core',  @Camera = '32 MP',  @HardDisk = '128 GB', @SIM = '2 Nano SI 5G'   

-- insert MayTinhBang
exec insertSanPham @ID = 'TBMB00001',  @ProdName = 'Samsung Galaxy Tab S7 FE',  @PriceIn = 9500000,  @Price = 13990000,  @Insurance = 12,  @Other = 'touch pen',  @Manufacture = 'Samsung',   @ProdType = 'Device', @Battery = '10090 mAh, 45 W',  @DateRelease = '01-01-2021',  @Screen = '12.4" TFT LCD', @RAM = '4 GB',  @DeviceType = 'Tablet',  @CPU_Chip = 'Snapdragon 750G',  @Camera = '8 MP',  @HardDisk = '64 GB'
exec insertSanPham @ID = 'TBMB00002',  @ProdName = 'iPad Pro M1',  @PriceIn = 32000000,  @Price = 39490000,  @Insurance = 18,  @Other = NULL,  @Manufacture = 'Apple',   @ProdType = 'Device', @Battery = '40.88 Wh, 20 W',  @DateRelease = '01-01-2021',  @Screen = '12.9" Liquid Retina XDR mini-LED LCD', @RAM = '8 GB',  @DeviceType = 'Tablet',  @CPU_Chip = 'Apple M1 8 core',  @Camera = '12 MP',  @HardDisk = '256 GB'
exec insertSanPham @ID = 'TBMB00003',  @ProdName = 'iPad Air 4',  @PriceIn = 19000000,  @Price = 22900000,  @Insurance = 12,  @Other = NULL,  @Manufacture = 'Apple',   @ProdType = 'Device', @Battery = '28.65 Wh, 20 W',  @DateRelease = '01-01-2020',  @Screen = '10.9" Liquid Retina', @RAM = '4 GB',  @DeviceType = 'Tablet',  @CPU_Chip = 'Apple A14 Bionic',  @Camera = '12 MP',  @HardDisk = '256 GB' 
exec insertSanPham @ID = 'TBMB00004',  @ProdName = 'iPad mini 6',  @PriceIn = 17500000,  @Price = 21990000,   @Insurance = 12,  @Other = NULL,  @Manufacture = 'Apple',   @ProdType = 'Device', @Battery = '19.3 Wh, 20 W',  @DateRelease = '01-01-2020',  @Screen = '8.3" LED-backlit IPS LCD', @RAM = '4 GB',  @DeviceType = 'Tablet',  @CPU_Chip = 'Apple A15 Bionic',  @Camera = '12 MP',  @HardDisk = '256 GB'

-- Insert Chuot
exec insertSanPham @ID = 'PKCH00001', @ProdName = 'Rapoo M20 Plus', @PriceIn = 100000, @Price = 200000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Rapoo', @ProdType = 'Accessory', @Connection = 'USB Receiver', @DeviceType = 'Mouse', @DPI = '1000'
exec insertSanPham @ID = 'PKCH00002', @ProdName = 'Rapoo M216', @PriceIn = 100000, @Price = 200000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Rapoo', @ProdType = 'Accessory', @Connection = 'USB Receiver', @DeviceType = 'Mouse', @DPI = '1000'
exec insertSanPham @ID = 'PKCH00003', @ProdName = 'Bluetooth Apple MK2E3', @PriceIn = 1000000, @Price = 2365000, @Insurance = 12, @Other = N'{"Màu": "Trắng"}', @Manufacture = 'Apple', @ProdType = 'Accessory', @Connection = 'Bluetooth', @DeviceType = 'Mouse', @DPI = '1300'
exec insertSanPham @ID = 'PKCH00004', @ProdName = 'Rapoo VT30', @PriceIn = 500000, @Price = 690000, @Insurance = 16, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Rapoo', @ProdType = 'Accessory', @Connection = 'USB Receiver', @DeviceType = 'Mouse', @DPI = '6200'
exec insertSanPham @ID = 'PKCH00005', @ProdName = 'Razer Viper Mini', @PriceIn = 700000, @Price = 1090000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Razer', @ProdType = 'Accessory', @Connection = 'Wired Cable', @DeviceType = 'Mouse', @DPI = '8500'
exec insertSanPham @ID = 'PKCH00006', @ProdName = 'HyperX Pulsefire FPS Pro', @PriceIn = 600000, @Price = 990000, @Insurance = 16, @Other = N'{"Màu": "Đen"}', @Manufacture = 'HyperX', @ProdType = 'Accessory', @Connection = 'USB Cable', @DeviceType = 'Mouse', @DPI = '16000'
exec insertSanPham @ID = 'PKCH00007', @ProdName = 'Corsair Nightsword', @PriceIn = 1000000, @Price = 2090000, @Insurance = 14, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Corsair', @ProdType = 'Accessory', @Connection = 'USB Cable', @DeviceType = 'Mouse', @DPI = '18000'
exec insertSanPham @ID = 'PKCH00008', @ProdName = 'Logitech M190', @PriceIn = 100000, @Price = 289000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Logitech', @ProdType = 'Accessory', @Connection = 'USB Receiver', @DeviceType = 'Mouse', @DPI = '1000'
exec insertSanPham @ID = 'PKCH00009', @ProdName = 'Microsoft Sculpt Comfort', @PriceIn = 500000, @Price = 1010000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = 'Microsoft', @ProdType = 'Accessory', @Connection = 'Bluetooth', @DeviceType = 'Mouse', @DPI = '1000'

-- insert TaiNghe
exec insertSanPham  @ID ='PKTN00001', @ProdName = N'LG TONE-FP8', @PriceIn = 3000000, @Price = 4190000, @Insurance = 12, @Other = N'{"Màu": "Đen", "Pin": "AA"}', @Manufacture = N'LG', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType = N'Wireless', @Battery = N'10 giờ'
exec insertSanPham  @ID ='PKTN00002', @ProdName = N'AirPods Pro MagSafe Charge Apple MLWK3', @PriceIn = 5000000, @Price = 6790000, @Insurance = 12, @Other = N'{"Màu": "Xanh", "Pin": "AA"}', @Manufacture = N'Apple', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType ='Wireless', @Battery = N'4.5 giờ'
exec insertSanPham  @ID ='PKTN00003', @ProdName = N'Bluetooth Beats Flex MYMC2', @PriceIn = 500000, @Price = 1290000, @Insurance = 12, @Other = N'{"Màu": "Trắng", "Pin": "AA"}', @Manufacture = N'Beats', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType = N'Wireless', @Battery = N'12 giờ'
exec insertSanPham  @ID ='PKTN00004', @ProdName = N'EP Gaming Rapoo VM150', @PriceIn = 200000, @Price = 499000, @Insurance = 12, @Other = N'{"Màu": "Hồng"}', @Manufacture = N'Rapoo', @ProdType = N'Accessory', @Connection = N'Jack 3.5mm', @DeviceType = N'Headphone', @HPhoneType ='Wired', @Battery = NULL
exec insertSanPham  @ID ='PKTN00005', @ProdName = N'Sony WF-C500', @PriceIn = 1000000, @Price = 2290000, @Insurance = 6, @Other = N'{"Màu": "Đen"}', @Manufacture = N'Sony', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType ='Wireless', @Battery = N'10 giờ'
exec insertSanPham  @ID ='PKTN00006', @ProdName = N'Rapoo H120', @PriceIn = 100000, @Price = 280000, @Insurance = 6, @Other = N'{"Màu": "Đen"}', @Manufacture = N'Rapoo', @ProdType = N'Accessory', @Connection = N'Jack USB', @DeviceType = N'Headphone', @HPhoneType ='Wired', @Battery = NULL
exec insertSanPham  @ID ='PKTN00007', @ProdName = N'Corsair HS50 PRO Stereo Carbon', @PriceIn = 1000000, @Price = 1290000, @Insurance = 12, @Other = N'{"Màu": "Vàng"}', @Manufacture = N'LG', @ProdType = N'Accessory', @Connection = N'Jack 3.5mm', @DeviceType = N'Headphone', @HPhoneType ='Wired', @Battery = NULL
exec insertSanPham  @ID ='PKTN00008', @ProdName = N'Bluetooth True Wireless Soundpeats Sonic', @PriceIn = 600000, @Price = 834000, @Insurance = 12, @Other = N'{"Màu": "Đen"}', @Manufacture = N'Soundpeats', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType = N'Wireless', @Battery = N'15 giờ'
exec insertSanPham  @ID ='PKTN00009', @ProdName = N'Bluetooth True Wireless Hydrus TS12BC', @PriceIn = 200000, @Price = 330000, @Insurance = 12, @Other = N'{"Màu": "Trắng", "Pin": "AA"}', @Manufacture = N'Hydrus', @ProdType = N'Accessory', @Connection = N'Bluetooth', @DeviceType = N'Headphone', @HPhoneType = N'Wireless', @Battery = N'3.5 giờ'

-- insert Hãng sản xuất
insert into HangSanXuat (ManuName, Addr, Phone) 
values	('Apple', 'Cupertino, California, America', '18002752273'),
		('Samsung', 'Samsung Town, Seocho-gu, Seoul, South Korea', '842839157310'), 
		('Acer', '5th Floor, Rosana Building, 60 Nguyen Dinh Chieu, Da Kao Ward, District 1, Ho Chi Minh City', '84839106888'),
		('Lenovo', 'Morrisville, North Carolina, America', NULL),
		('Gigabyte', 'Tan Bac, Dai Loan', NULL),
		('Asus', 'Bac Đau, Dai Bac, Dai Loan', '18006588'),
		('Xiaomi', 'Hai Dien, Bac Kinh, Trung Quoc', '0333553131'),
        ('Rapoo', '22, Jinxiu Road East, Pingshan DistrictShenzhenChina', '28588666'),
        ('Razer', 'Hamburg, Germany', '419299300'),
        ('HyperX', '17600 Newhope Street Fountain Valley, CA 92708 USA', '4352600'),
        ('Corsair', 'BAYSIDE PARKWAY. FREMONT, CA 94538', '5106578747'),
        ('Logitech', '7700 Gateway Blvd. Newark, CA 94560 USA', '5107958500'),
        ('Microsoft', 'Redmond, Washington', '8555426924'),
        ('LG', N' CN2, KCN Tràng Duệ, xã Lê Lợi, huyện An Dương, thành phố Hải Phòng, Việt Nam', '02439345151'),
        ('Beats', '8600 Hayden Place Culver City, CA 90232 USA','18004424000'),
        ('Sony', N'11 Yết Kiêu, Vạn Thắng, Thành phố Nha Trang, Khánh Hòa', '02583813980'),
        ('Soundpeats', 'Sesam Street 323b, 4010, Norway','8559974505'),
        ('Hydrus', 'Brechin Business Park, Brechin, Angus', '1356 622 044');

-- insert CTKM_SanPham
insert into CTKM_SanPham (ID, TimeStart, TimeEnd, PromoLevel)
values  ('KMSP00006', '2021-11-20', '2021-12-12', 35),
		('KMSP00007', '2021-12-01', '2021-12-30', 40),
		('KMSP00008', '2021-11-25', '2021-12-25', 10),
		('KMSP00009', '2021-11-01', '2022-02-03', 15),
		('KMSP00010', '2021-12-01', '2021-12-30', 20),
        ('KMSP00001', '2021-11-11', '2021-12-12', 45),
        ('KMSP00002', '2021-10-14', '2021-11-30', 20),
        ('KMSP00003', '2021-11-25', '2021-12-25', 10),
        ('KMSP00004', '2021-11-01', '2021-12-01', 15),
        ('KMSP00005', '2021-11-01', '2021-11-30', 20);

-- insert SanPham_ApDung_CTKM
insert into SanPham_ApDung_CTKM (ID_Ad, ID_Prod)
values	('KMSP00006', 'TBLT00002'),
		('KMSP00008', 'TBMB00003'),
		('KMSP00009', 'TBLT00001'),
		('KMSP00010', 'TBDT00003'),
		('KMSP00007', 'TBDT00005'),
		('KMSP00006', 'TBMB00004'),
		('KMSP00008', 'TBMB00001'),
		('KMSP00001', 'PKTN00001'),
		('KMSP00002', 'PKTN00005'),
		('KMSP00003', 'PKTN00002'),
		('KMSP00004', 'PKTN00009'),
		('KMSP00005', 'PKCH00008'),
		('KMSP00001', 'PKCH00002'),
		('KMSP00002', 'PKCH00004')

-- insert NhanVien
insert into NhanVien (ID, Username, Passwd, IdNum, Phone, Salary, Bdate, Fname, Lname, Email, Addr, ID_branch) values
	('1', 'dangtu2001', 'tu123456', '212716385', '0331263856', 18000000, '12-07-2001', N'Nguyễn Đăng', N'Tú', 'tu123@gmail.com', N'Mộ Đức, Quảng Ngãi', '1'),
	('2', 'dangquan1996', 'quan123456', '212716465', '0336124764', 10000000, '03-04-1996', N'Nguyễn Đăng', N'Quân', 'quan123@gmail.com', N'Mộ Đức, Quảng Ngãi', '1'),
	('3', 'tuananh1995', 'anh123456', '212343126', '0949445728', 8000000, '12-03-1995', N'Bùi Tuấn', 'Anh', 'anh123@gmail.com', N'Tư Nghĩa, Quảng Ngãi', '1'),
	('4', 'honganh2000', 'hanh123456', '211416235', '0396414368', 8500000, '12-02-2000', N'Võ Hồng', N'Ánh', 'hanh123@gmail.com', N'Nghĩa Hành, Quảng Ngãi', '1'),
	('5', 'hungcuong1994', 'cuong123456', '212345638', '0349781353', 8000000, '03-12-1994', N'Phan Hùng', N'Cường', 'cuong123@gmail.com', N'Mộ Đức, Quảng Ngãi', '1'),
	('6', 'lamthao1994', 'thao123456', '213416985', '0376529187', 18000000, '02-10-1994', N'Ba Ngọc Lam', 'thao', 'thao123@gmail.com', N'Mộ Đức, Quảng Ngãi', '2'),
	('7', 'ducbao1990', 'bao123456', '213218160', '0347483567', 10000000, '04-23-1990', N'Trần Đức', N'Bảo', 'bao123@gmail.com', N'Nghĩa Hành, Quảng Ngãi', '2'),
	('8', 'bichdieu1992', 'dieu123456', '213415642', '0967217358', 9000000, '02-18-1992', N'Lê Bích', N'Diệu', 'dieu123@gmail.com', N'Mộ Đức, Quảng Ngãi', '2'),
	('9', 'tanbut2000', 'but123456', '212718752', '0332142856', 8000000, '03-09-2000', N'Đỗ Tấn', N'Bút', 'but123@gmail.com', N'Ba Tơ, Quảng Ngãi', '2'),
	('10', 'hanhgiang1995', 'giang123456', '212314927', '0923167840', 12000000, '12-17-1995', N'Nguyễn Hạnh', N'Giang', 'giang123@gmail.com', N'Mộ Đức, Quảng Ngãi', '2'),
	('11', 'tuantrai1990', 'trai123456', '211911337', '0394521678', 18000000, '02-13-1990', N'Trần Tuấn', N'Trãi', 'trai123@gmail.com', N'Đức Phổ, Quảng Ngãi', '3'),
	('12', 'leduan1987', 'duan123456', '213412845', '0125234945', 12000000, '05-14-1987', N'Nguyễn Lê', N'Duẩn', 'duan123@gmail.com', N'Nghĩa Hành, Quảng Ngãi', '3'),
	('13', 'minhthuy2000', 'thuy123456', '212317840', '0338741365', 10000000, '01-07-2000', N'Lê Minh', N'Thùy', 'thuy123@gmail.com', N'TP Quảng Ngãi, Quảng Ngãi', '3'),
	('14', 'camvien1994', 'vien123456', '212117438', '0325498174', 8500000, '11-15-1994', N'Võ Cẩm', N'Viên', 'vien123@gmail.com', N'Trà Bồng, Quảng Ngãi', '3'),
	('15', 'thuytrang1996', 'trang123456', '211314135', '0394528145', 9000000, '03-11-1956', N'Phan Thùy', 'Trang', 'trang123@gmail.com', N'Sơn Trà, Quảng Ngãi', '3');

-- insert NguoiThan
insert into NguoiThan (ID_Employee, Fname, Lname, Addr, Phone, Relation) values 
	('1', N'Ngô Thị', N'Lệ', N'Mộ Đức, Quảng Ngãi', N'0345618274', N'Mẹ'),
	('1', N'Nguyễn Đăng', N'Lênh', N'Mộ Đức, Quảng Ngãi', N'0949247185', N'Cha'),
	('2', N'Ngô', N'Lệ', N'Mộ Đức, Quảng Ngãi', N'0395661274', N'Mẹ'),
	('3', N'Trần Thị', N'Thắm', N'Tư Nghĩa, Quảng Ngãi', N'0395626874', N'Mẹ'),
	('4', N'Võ Lê', N'Thanh', N'Nghĩa Hành, Quảng Ngãi', N'0923176289', N'Cha'),
	('5', N'Lê Thanh', N'Thủy', N'Mộ Đức, Quảng Ngãi', N'0345361274', N'Mẹ'),
	('6', N'Bạch Ngọc', N'Thảo', N'Mộ Đức, Quảng Ngãi', N'0346195438', N'Cha'),
	('8', N'Lê Thị', N'Thúy', N'Mộ Đức, Quảng Ngãi', N'0373881274', N'Mẹ'),
	('9', N'Đỗ Tấn', N'Thanh', N'Ba Tơ, Quảng Ngãi', N'0345743574', N'Cha'),
	('10', N'Huỳnh Ngọc', N'Ly', N'Mộ Đức, Quảng Ngãi', N'0312891274', N'Mẹ'),
	('11', N'Trần Bá', N'Dũng', N'Đức Phổ, Quảng Ngãi', N'0949127284', N'Cha'),
	('11', N'Hoàng Thị', N'Linh', N'Đức Phổ, Quảng Ngãi', N'0313631274', N'Mẹ'),
	('13', N'Lê Minh', N'Dũng', N'TP Quảng Ngãi, Quảng Ngãi', N'0923145274', N'Cha'),
	('15', N'Trần Thùy', N'Linh', N'Sơn Trà, Quảng Ngãi', N'0143731745', N'Mẹ');

-- insert ChiNhanh
insert into ChiNhanh (ID, BranchName, Addr, ID_Manager) values 
	('1', N'Di động bách khoa - Mộ Đức', N'Mộ Đức, Quảng Ngãi', 1),
	('2', N'Di động bách khoa - TP Quảng Ngãi', N'TP Quảng Ngãi, Quảng Ngãi', 6),
	('3', N'Di động bách khoa - Đức Phổ', N'Đức Phổ, Quảng Ngãi', 11);
 
-- insert SDT Chi Nhanh
insert into SDTChiNhanh (ID_Branch, Phone) values 
	('1', '0949234104'),
	('1', '0944128514'),
	('2', '0355174375'),
	('2', '0923185165'),
	('3', '0325174287'),
	('3', '0957193175');
go

insert into ChiNhanh_Ban_SanPham (ID_Prod, ID_Branch, Quantity) values
('TBLT00001', '1', 10), ('TBLT00002', '1', 50), ('TBLT00007', '1', 30), ('TBLT00004', '1', 33), ('TBLT00005', '1', 60),
('TBDT00001', '1', 30), ('TBDT00002', '1', 40), ('TBDT00003', '1', 35), ('TBDT00004', '1', 46), ('TBDT00005', '1', 30), 
('TBMB00001', '1', 10), ('TBMB00002', '1', 50), ('TBMB00003', '1', 30), ('TBMB00004', '1', 33), 
('PKCH00001', '1', 30), ('PKCH00002', '1', 40), ('PKCH00003', '1', 35), ('PKCH00004', '1', 46), ('PKCH00005', '1', 20), ('PKCH00006', '1', 10), ('PKCH00007', '1', 50), ('PKCH00008', '1', 100), ('PKCH00009', '1', 70),
('PKTN00001', '1', 10), ('PKTN00002', '1', 50), ('PKTN00003', '1', 30), ('PKTN00004', '1', 33), ('PKTN00005', '1', 20), ('PKTN00006', '1', 90), ('PKTN00007', '1', 80), ('PKTN00008', '1', 50), ('PKTN00009', '1', 60),
('TBLT00001', '2', 30), ('TBLT00002', '2', 40), ('TBLT00007', '2', 35), ('TBLT00004', '2', 46), ('TBLT00005', '2', 20),
('TBDT00001', '2', 10), ('TBDT00002', '2', 50), ('TBDT00003', '2', 30), ('TBDT00004', '2', 33), ('TBDT00005', '2', 40), 
('TBMB00001', '2', 30), ('TBMB00002', '2', 40), ('TBMB00003', '2', 35), ('TBMB00004', '2', 46), 
('PKCH00001', '2', 10), ('PKCH00002', '2', 50), ('PKCH00003', '2', 30), ('PKCH00004', '2', 33), ('PKCH00005', '2', 20), ('PKCH00006', '2', 10), ('PKCH00007', '2', 50), ('PKCH00008', '2', 100), ('PKCH00009', '2', 70),
('PKTN00001', '2', 30), ('PKTN00002', '2', 40), ('PKTN00003', '2', 35), ('PKTN00004', '2', 46), ('PKTN00005', '2', 20), ('PKTN00006', '2', 90), ('PKTN00007', '2', 80), ('PKTN00008', '2', 50), ('PKTN00009', '2', 60),
('TBLT00001', '3', 10), ('TBLT00002', '3', 50), ('TBLT00007', '3', 30), ('TBLT00004', '3', 33), ('TBLT00005', '3', 90),
('TBDT00001', '3', 30), ('TBDT00002', '3', 40), ('TBDT00003', '3', 35), ('TBDT00004', '3', 46), ('TBDT00005', '3', 30), 
('TBMB00001', '3', 20), ('TBMB00002', '3', 50), ('TBMB00003', '3', 30), ('TBMB00004', '3', 33), 
('PKCH00001', '3', 30), ('PKCH00002', '3', 40), ('PKCH00003', '3', 35), ('PKCH00004', '3', 46), ('PKCH00005', '3', 90), ('PKCH00006', '3', 80), ('PKCH00007', '3', 60), ('PKCH00008', '3', 30), ('PKCH00009', '3', 20),
('PKTN00001', '3', 15), ('PKTN00002', '3', 30), ('PKTN00003', '3', 75), ('PKTN00004', '3', 26), ('PKTN00005', '3', 23), ('PKTN00006', '3', 20), ('PKTN00007', '3', 44), ('PKTN00008', '3', 55), ('PKTN00009', '3', 10)

-- Insert Khach hang
insert into KhachHang (ID, Username, Passwd, Phone, Fname, Lname, Email, Bdate, IdNum, FamScore) values
		('1', 'tk_0341', 'bA@22mt67', '0986234651', N'Lê Bảo', N'Nhân', 'nhanlb@gmail.com', '04-01-2001', '212867091', 500),
		('2', 'nguyenle10', 'Nguyenle101001', '0384657091', N'Lê Hoàng', N'Nguyên', 'nguyen10@gmail.com', '07-03-1996', '206751389', 2000),
		('3', 'smtk7117', 'qweasd123', '0169425111', N'Trần Long', N'Phú', 'phutran@gmail.com', '1999-10-24', '210756043', 500),
		('4', 'x12345x', 'hmdbTY10', '0965487132', N'Huỳnh Hương', N'Trúc', 'truchuonghuynh@gmail.com', '2000-07-15', '211567801', 1000),
		('5', 'ghbv1kj34', 'vVvbBb_54321', '0841791421', N'Ngô Thị Mỹ', N'Hoa', 'hoantm@gmail.com', '10-04-1997', '208741223', 1500),
		('6', 'tiendang123', 'TienDang321', '0916381208', N'Đặng Văn', N'Tiến', 'tien_123@gmail.com', '2001-07-17', '212945708', 0),
		('7', 'tngk0812', 'tngk_0812', '0972124356', N'Trần Nguyễn Gia', N'Kim', 'kimgia@gmail.com', '08-12-2002', '213056432', 2000),
		('8', 'thanh0123', 'Thanh012@3', '0167103459', N'Hàn Vũ', N'Thanh', 'thanhvh@gmail.com', '1998-03-27', '209945112', 5000),
		('9', 'mmt211', 'tgbnhy56', '0364721309', N'Dương', N'Minh', 'minhduong@gmail.com', '03-06-1999', '210785439', 500),
		('10', 'xkht_453', 'TLHnbv098', '0734768901', N'Đỗ Kiều Minh', N'Liên', 'liendo111@gmail.com', '2000-08-14', '211412567', 0),
		('11', 'dalkks12', 'dal_kks_12', '0842608792', N'Võ Thiên', N'Mệnh', 'menhvo@gmail.com', '1995-02-20', '200032589', 500),
		('12', 'mincut4532', 'MiC_0987', '0126982301', N'Nguyễn Vĩnh An', N'Khang', 'khangnva@gmail.com', '05-05-1998', '210379412', 0),
		('13', 'trinhan1289', 'Trinhan_1289', '0376513702', N'Trịnh', N'Án', 'antrinh1289@gmail.com', '12-11-1997', '207976854', 4000),
		('14', 'khucnghiem123', 'KHUC_nghiem_123', '0986412213', N'Nghiêm', N'Khúc', 'khucnghiem@gmail.com', '2001-01-15', '212976321', 3500),
		('15', 'tambao0808', 'baotam0808', '0888123765', N'Lý Kim Bảo', N'Tâm', 'tambao0808@gmail.com', '08-08-1996', '205930462', 1000);

-- Insert Gioi thieu
insert into GioiThieu (IDRef, ID) values
		('8', '9'),
		('8', '14'),
		('2', '5'),
		('13', '15'),
		('15', '2');
 
-- Insert Chuong trinh khuyen mai don hang
insert into CTKM_DonHang (ID, TimeStart, TimeEnd, PromoLevel, Condition) values
		('KMDH00001', '2019-02-10', '2019-02-20', 5, 500000),
		('KMDH00002', '2020-01-01', '2020-01-05', 10, 2000000),
		('KMDH00003', '2020-12-15', '2021-01-15', 10, 2000000),
		('KMDH00004', '2021-09-09', '2021-09-09', 15, 4000000);

 
alter table GioiThieu
add foreign key (IDRef) references KhachHang(ID),
	foreign key (ID) references KhachHang(ID);
go
 
alter table DonHang
add foreign key (ID_Customer) references KhachHang(ID),
	foreign key (ID_Employee) references NhanVien(ID),
	foreign key (ID_Ad) references CTKM_DonHang(ID);
go
 
alter table SanPham_Thuoc_DonHang
add foreign key (ID_Prod) references SanPham(ID),
	foreign key (ID_Order) references DonHang(ID) on update cascade on delete cascade;
go
 
alter table NguoiThan
add foreign key (ID_Employee) references NhanVien(ID);
go
 
alter table NhanVien
add foreign key (ID_branch) references ChiNhanh(ID);
go
 
alter table SDTChiNhanh
add foreign key (ID_Branch) references ChiNhanh(ID);
go
 
alter table ChiNhanh
add foreign key (ID_Manager) references NhanVien(ID);
go
 
alter table ChiNhanh_Ban_SanPham
add foreign key (ID_Branch) references ChiNhanh(ID),
	foreign key (ID_Prod) references SanPham(ID) on update cascade on delete cascade;
go
 
alter table SanPham
add foreign key (manufacture) references HangSanXuat(ManuName);
go
 
alter table SanPham_ApDung_CTKM
add foreign key (ID_Prod) references SanPham(ID) on update cascade on delete cascade,
	foreign key (ID_Ad) references CTKM_SanPham(ID) on update cascade on delete cascade;
go

alter table ThietBiDienTu
add foreign key (ID) references SanPham(ID) on update cascade on delete cascade;
alter table PhuKien
add foreign key (ID) references SanPham(ID) on update cascade on delete cascade;
go
 
alter table Laptop
add foreign key (ID) references ThietBiDienTu(ID) on update cascade on delete cascade;
alter table DienThoai
add foreign key (ID) references ThietBiDienTu(ID) on update cascade on delete cascade;
alter table MayTinhBang
add foreign key (ID) references ThietBiDienTu(ID) on update cascade on delete cascade;
go
 
alter table TaiNghe
add foreign key (ID) references PhuKien(ID) on update cascade on delete cascade;
alter table Chuot
add foreign key (ID) references PhuKien(ID) on update cascade on delete cascade;
go

select * from ChiNhanh
select * from SDTChiNhanh
select * from NhanVien
select * from NguoiThan

select * from KhachHang
select * from GioiThieu

select * from CTKM_DonHang
select * from DonHang
select * from SanPham_Thuoc_DonHang

select * from CTKM_SanPham
select * from SanPham_ApDung_CTKM

select * from ChiNhanh_Ban_SanPham
select * from HangSanXuat
select * from SanPham
select * from ThietBiDienTu
select * from Laptop
select * from MayTinhBang
select * from DienThoai
select * from PhuKien
select * from Chuot
select * from TaiNghe
