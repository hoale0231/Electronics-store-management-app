use db_a2;
go

-- Cau 1
create or alter procedure InsertDonHang
	-- Don hang
	@id				char(9),
	@timeCreated	date			= null,
	@sumPrices		int				= 0,
	@id_customer	char(9),
	@id_employee	char(9),
	@id_ad			char(9)			= null
as
begin
	set nocount on;
		-- Insert Don hang
		if @timeCreated is null
		begin
			set @timeCreated = getdate();
		end
		if @sumPrices < 0
		begin
			raiserror('Invalid SumPrices !', 16, 1);
			return;
		end;
		if not exists(select * from KhachHang where ID = @id_customer)
		begin
			raiserror('No customer with ID: %s', 16, 1, @id_customer);
			return;
		end
		if not exists(select * from NhanVien where ID = @id_employee)
		begin
			raiserror('No employee with ID: %s', 16, 1, @id_employee);
			return;
		end
		if @id_ad is not null and not exists(select * from CTKM_DonHang where ID = @id_ad)
		begin
			raiserror('No order sales with ID: %s', 16, 1, @id_ad);
			return;
		end
		insert into DonHang (ID, TimeCreated, SumPrices, ID_Customer, ID_Employee, ID_Ad)
		values				(@id, @timeCreated, @sumPrices, @id_customer, @id_employee, @id_ad)
	set nocount off;
end;
go

-- Cau 2
-- Trigger 1
create or alter trigger CheckCTKMDH on CTKM_DonHang for insert
as
begin
	set nocount on;
		declare @timeStart date, @timeEnd date, @promoLevel int, @condition int;
		declare kmCursor cursor for select TimeStart, TimeEnd, PromoLevel, Condition from inserted;
		open kmCursor;
		fetch next from kmCursor into @timeStart, @timeEnd, @promoLevel, @condition;
		while @@FETCH_STATUS = 0
		begin 
			if (@timeStart > @timeEnd)
			begin
				raiserror('TimeStart must be not larger than TimeEnd!', 16, 1);
				rollback;
			end;
			if (@promoLevel <= 0)
			begin
				raiserror('Invalid PromoLevel!', 16, 1);
				rollback;
			end
			if (@condition < 0)
			begin
				raiserror('Invalid Condition!', 16, 1);
				rollback;
			end
			fetch next from kmCursor into @timeStart, @timeEnd, @promoLevel, @condition;
		end
		close kmCursor;
		deallocate kmCursor;
	set nocount off;
end;
go

-- Trigger 2
create or alter trigger DHinsertSP on SanPham_Thuoc_DonHang for insert, update, delete
as
begin
	set nocount on;
		declare @price int, @qty int, @productID char(9), @orderID char(9);
		declare @promoLevel int;
		-- insert
		declare orderCursor cursor for select ID_Order, ID_Prod, Price, Quantity from inserted;
		open orderCursor;
		fetch next from orderCursor into @orderID, @productID, @price, @qty;
		while @@FETCH_STATUS = 0
		begin
			if @price < 0
			begin
				raiserror('Invalid Prices!', 16, 1);
				rollback;
			end
			if @qty < 0
			begin
				raiserror('Invalid Quantity!', 16, 1);
				rollback;
			end
			select @promoLevel = PromoLevel 
			from CTKM_DonHang, DonHang
			where DonHang.ID_Ad = CTKM_DonHang.ID and DonHang.ID = @orderID;
			if @promoLevel is null
				set @promoLevel = 0;
			update DonHang
			set SumPrices = SumPrices + @price*@qty*(1 - @promoLevel*0.01)
			where ID = @orderID
			fetch next from orderCursor into @orderID, @productID, @price, @qty;
		end
		close orderCursor;
		deallocate orderCursor;

		-- delete
		declare orderCursor cursor for select ID_Order, ID_Prod, Price, Quantity from deleted;
		open orderCursor;
		fetch next from orderCursor into @orderID, @productID, @price, @qty;
		while @@FETCH_STATUS = 0
		begin
			select @promoLevel = PromoLevel 
			from CTKM_DonHang, DonHang
			where DonHang.ID_Ad = CTKM_DonHang.ID and DonHang.ID = @orderID;
			if @promoLevel is null
				set @promoLevel = 0;
			update DonHang
			set SumPrices = SumPrices - @price*@qty*(1 - @promoLevel*0.01)
			where ID = @orderID
			fetch next from orderCursor into @orderID, @productID, @price, @qty;
		end
		close orderCursor;
		deallocate orderCursor;
	set nocount off;
end;
go

-- Cau 3
-- Procedure 1
create or alter procedure InfoOrder
	@id_order char(9)
as
begin
	select SanPham_Thuoc_DonHang.ID_Order as ID_Order, SanPham.ProdName as Product_Name, SanPham.ProdType as Product_Type, ThietBiDienTu.DeviceType as Device_Type, SanPham.Price as Product_Price, SanPham_Thuoc_DonHang.Quantity as Quantity
	from SanPham_Thuoc_DonHang, SanPham, ThietBiDienTu
	where SanPham_Thuoc_DonHang.ID_Prod = SanPham.ID and SanPham_Thuoc_DonHang.ID_Prod = ThietBiDienTu.ID and SanPham_Thuoc_DonHang.ID_Order = @id_order 
	union
	select SanPham_Thuoc_DonHang.ID_Order as ID_Order, SanPham.ProdName as Product_Name, SanPham.ProdType as Product_Type, PhuKien.AccsoryType as Device_Type, SanPham.Price as Product_Price, SanPham_Thuoc_DonHang.Quantity as Quantity
	from SanPham_Thuoc_DonHang, SanPham, PhuKien
	where SanPham_Thuoc_DonHang.ID_Prod = SanPham.ID and SanPham_Thuoc_DonHang.ID_Prod = PhuKien.ID and SanPham_Thuoc_DonHang.ID_Order = @id_order
	order by SanPham.ProdType, SanPham.ProdName
end;
go

-- Procedure 2
create or alter procedure LikedProduct (@prodType nvarchar(100) = 'All')
as
begin
	select SanPham.ProdName as Product_Name, SanPham.ProdType as Product_Type, SanPham.Price as Product_Price, numSP.SumQuantity as Sold
	from SanPham, (	select SanPham_Thuoc_DonHang.ID_Prod as ID_Product, sum(Quantity) as SumQuantity
					from SanPham_Thuoc_DonHang, SanPham
					where SanPham_Thuoc_DonHang.ID_Prod = SanPham.ID
					group by SanPham_Thuoc_DonHang.ID_Prod, SanPham.ProdType
					having SanPham.ProdType = @prodType or @prodType = 'All') as numSP
	where SanPham.ID = numSP.ID_Product
	order by numSP.SumQuantity desc, SanPham.ProdName
end;
go

-- Cau 4
-- Function 1
create or alter function GetID_CTKM(@id_order char(9))
returns char(9)
as
begin
	declare @maxPLevel int, @id_use char(9);
	declare @timeCreated date, @sumPrices int, @id_ad char(9);
	declare @id char(9), @timeStart date, @timeEnd date, @promoLevel int, @condition int;
	set @maxPLevel = 0;
	if (not exists(select * from DonHang where ID = @id_order))
	begin
		return cast('No order with ID: ' + @id_order as char(9));
	end
	select @timeCreated = TimeCreated, @sumPrices = SumPrices, @id_ad = ID_Ad
	from DonHang
	where ID = @id_order
	declare kmCursor cursor for select * from CTKM_DonHang;
	open kmCursor;
	fetch next from kmCursor into @id, @timeStart, @timeEnd, @promoLevel, @condition;
	while @@FETCH_STATUS = 0
	begin
		if @timeCreated >= @timeStart and @timeCreated <= @timeEnd and @sumPrices >= @condition
		begin
			if @promoLevel > @maxPLevel
				begin
					set @maxPLevel = @promoLevel;
					set @id_use = @id;
				end
		end
		fetch next from kmCursor into @id, @timeStart, @timeEnd, @promoLevel, @condition;
	end
	close kmCursor;
	deallocate kmCursor;
	return @id_use;
end;
go

-- Function 2
create or alter function NumEachType(@id_order char(9))
returns @category table (ID_Order char(9), Num_Device int, Num_Accessory int)
as
begin
	declare @numID int, @numDevice int, @numAccessory int;

	if (not exists(select * from DonHang where ID = @id_order))
	begin
		insert into @category values (cast('No order with ID: ' + @id_order as char(9)), null, null)
		return
	end

	select @numDevice = count(*)
	from SanPham_Thuoc_DonHang, SanPham
	where SanPham_Thuoc_DonHang.ID_Order = @id_order and SanPham_Thuoc_DonHang.ID_Prod = SanPham.ID and SanPham.ProdType = 'Device';

	select @numAccessory = count(*)
	from SanPham_Thuoc_DonHang, SanPham
	where SanPham_Thuoc_DonHang.ID_Order = @id_order and SanPham_Thuoc_DonHang.ID_Prod = SanPham.ID and SanPham.ProdType = 'Accessory';

	insert into @category values (@id_order, @numDevice, @numAccessory);
	return;
end;
go

-- Test
-- Cau 1
-- Insert Don hang
exec InsertDonHang @id = 'DH0000001', @timeCreated = '01-04-2020', @sumPrices = 0, @id_customer ='11', @id_employee = '7', @id_ad = 'KMDH00002'
exec InsertDonHang @id = 'DH0000002', @timeCreated = '10-10-2020', @sumPrices = 0, @id_customer ='10', @id_employee = '9'
exec InsertDonHang @id = 'DH0000003', @timeCreated = '01-14-2021', @sumPrices = 0, @id_customer ='15', @id_employee = '1', @id_ad = 'KMDH00003'
exec InsertDonHang @id = 'DH0000004', @timeCreated = '09-09-2021', @sumPrices = 0, @id_customer ='14', @id_employee = '5', @id_ad = 'KMDH00004'
exec InsertDonHang @id = 'DH0000005', @timeCreated = '11-30-2021', @sumPrices = 0, @id_customer ='7', @id_employee = '4'
exec InsertDonHang @id = 'DH0000006', @id_customer ='2', @id_employee = '2'
exec InsertDonHang @id = 'DH0000005', @timeCreated = '11-30-2021', @sumPrices = -1, @id_customer ='7', @id_employee = '4'
exec InsertDonHang @id = 'DH0000005', @timeCreated = '11-30-2021', @sumPrices = 0, @id_customer ='20', @id_employee = '10'

select * from DonHang
go

-- Cau 2
insert into CTKM_DonHang (ID, TimeStart, TimeEnd, PromoLevel, Condition) values ('KMDH00005', '11-30-2021', '12-05-2021', 5, 10000000)
insert into CTKM_DonHang (ID, TimeStart, TimeEnd, PromoLevel, Condition) values ('KMDH00006', '12-06-2021', '12-06-2021', 10, 10000000)
insert into CTKM_DonHang (ID, TimeStart, TimeEnd, PromoLevel, Condition) values ('KMDH00007', '12-06-2021', '12-07-2021', 10, -1)
insert into CTKM_DonHang (ID, TimeStart, TimeEnd, PromoLevel, Condition) values ('KMDH00008', '12-06-2021', '11-06-2021', 10, 10000000)

select * from CTKM_DonHang
go
-- Insert San pham thuoc don hang
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000001', 'TBLT00001', 29690000, 2);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000002', 'TBLT00007', 28000000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000003', 'TBLT00007', 28000000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000004', 'TBLT00007', 28000000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000004', 'TBDT00001', 22990000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000003', 'PKCH00001', 200000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000001', 'PKTN00001', 4190000, 2);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000004', 'PKTN00001', 4190000, 1);
insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values ('DH0000005', 'TBDT00001', 22990000, 1);
select * from SanPham_Thuoc_DonHang
go

-- Cau 3
exec InfoOrder @id_order = 'DH0000004';
exec LikedProduct @prodType = 'Device';
exec LikedProduct @prodType = 'Accessory';
exec LikedProduct @prodType = 'All';

-- Cau 4
select dbo.GetID_CTKM('DH0000005') 

select * from NumEachType('DH0000004')