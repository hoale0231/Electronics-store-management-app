go
create or alter procedure applySalesForBrand 
		@salesID	char(9),
		@brandName	nvarchar(100)
as
begin
	if not EXISTS(select * from CTKM_SanPham where ID = @salesID)
	begin
		RAISERROR('No sales with ID: %s', 16, 1, @salesID);
		return;
	end
		
	if not EXISTS(select * from HangSanXuat where ManuName = @brandName)
	begin
		RAISERROR('No manufacturer with name: %s', 16, 1, @brandName);
		return;
	end

	insert into SanPham_ApDung_CTKM
	select SanPham.ID, CTKM_SanPham.ID
	from CTKM_SanPham, SanPham
	where CTKM_SanPham.ID = @salesID and SanPham.manufacture = @brandName
end
go

/*-----------------------------------------------------------------------------------------------------------------*/
--Trigger 1
go
create or alter trigger checkDiscountApply
on SanPham_ApDung_CTKM
for insert, update
as
begin
	select Price, PriceIn, PromoLevel
	into #PriceCheck
	from SanPham, inserted, CTKM_SanPham
	where SanPham.Id = inserted.ID_Prod and CTKM_SanPham.Id = inserted.ID_Ad

	if (EXISTS(select * from #PriceCheck where PriceIn * 80 / 100 > Price * (100 - PromoLevel) / 100))
	begin
		RAISERROR ('Invalid discount. Price after discount has to be larger than 80% of import price.', 16, 1);
		rollback TRANSACTION;
	end;

	--All the sales applied to the product, exclude the newly added sales 
	select inserted.ID_Prod as ID_Prod, TimeStart, TimeEnd 
	into #TimeCheck
	from SanPham_ApDung_CTKM, CTKM_SanPham, inserted
	where SanPham_ApDung_CTKM.Id_Prod = inserted.Id_Prod and 
		  SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID and
		  not (inserted.ID_Ad = CTKM_SanPham.ID)

	if (EXISTS(select *
				from #TimeCheck, inserted, CTKM_SanPham
				where #TimeCheck.ID_Prod = inserted. ID_Prod and inserted.ID_Ad = CTKM_SanPham.ID 
						and #TimeCheck.TimeStart <= CTKM_SanPham.TimeStart
						and CTKM_SanPham.TimeStart <= #TimeCheck.TimeEnd))
	begin
		RAISERROR ('A product cannot have 2 overlapping sales.', 16, 1);
		rollback TRANSACTION;
	end
end

--Trigger 2
go
create or alter trigger checkValidDiscount
on CTKM_SanPham
for insert, update
as
begin
	if EXISTS(select * from inserted where ID NOT LIKE('KMSP%'))
	begin
		RAISERROR('Invalid ID format. ID has to start with KMSP', 16, 1)
		rollback TRANSACTION;
	end

	if EXISTS(select * from inserted where TimeStart >= TimeEnd)
	begin
		RAISERROR('Invalid date. Start time must come before end time', 16, 1)
		rollback TRANSACTION;
	end

	if EXISTS(select * from inserted where PromoLevel < 0 or PromoLevel > 100)
	begin
		RAISERROR('Invalid discount rate. Discount rate must be between 0 and 100', 16, 1)
		rollback TRANSACTION
	end

	--Remove invalid applied items after changing the discount rate.
	select SanPham.ID as ID_Prod, inserted.ID as ID_Ad
	into #PriceInvalidItem
	from SanPham, inserted, SanPham_ApDung_CTKM
	where SanPham.Id = SanPham_ApDung_CTKM.ID_Prod and SanPham_ApDung_CTKM.ID_Ad = inserted.ID
			and PriceIn * 80 / 100 > Price * (100 - PromoLevel) / 100
	
	delete from SanPham_ApDung_CTKM
	where ID_Prod in (select ID_Prod from #PriceInvalidItem)
		 and ID_Ad in (select ID_Ad from #PriceInvalidItem)

	--Remove invalid applied items after changing the event date.
	select SanPham_ApDung_CTKM.ID_Prod as ID_Prod, inserted.ID as ID_Ad, inserted.TimeStart as TimeStart, inserted.TimeEnd as TimeEnd
	into #TimeAffectedItem
	from SanPham_ApDung_CTKM, inserted
	where SanPham_ApDung_CTKM.ID_Ad = inserted.ID

	select #TimeAffectedItem.ID_Prod as ID_Prod, #TimeAffectedItem.ID_Ad as ID_Ad
	into #TimeInvalidItem
	from #TimeAffectedItem, SanPham_ApDung_CTKM, CTKM_SanPham
	where SanPham_ApDung_CTKM.Id_Prod = #TimeAffectedItem.Id_Prod and
		  SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID and
		  not (#TimeAffectedItem.ID_Ad = CTKM_SanPham.ID) and
		  CTKM_SanPham.TimeStart <= #TimeAffectedItem.TimeStart and
		  #TimeAffectedItem.TimeStart <= CTKM_SanPham.TimeEnd

	delete from SanPham_ApDung_CTKM
	where ID_Prod in (select ID_Prod from #TimeInvalidItem) and
		ID_Ad in (select ID_Ad from #TimeInvalidItem)
end


/*-----------------------------------------------------------------------------------------------------------------*/
--Ex3a: Get all sales of a product in a time period
go
create or alter procedure getSalesByProduct
		@Id_Prod char(9),
		@StartTime date,
		@EndTime date
as
	begin
		select ID_Prod, ProdName, ID_Ad, TimeStart, TimeEnd, PromoLevel
		from CTKM_SanPham, SanPham_ApDung_CTKM, SanPham
		where SanPham_ApDung_CTKM.ID_Prod = @Id_Prod and
			  SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID and
			  CTKM_SanPham.TimeStart >= @StartTime and
			  CTKM_SanPham.TimeStart <= @EndTime and 
			  SanPham.ID = @Id_Prod
		order by TimeStart
	end;


--Ex3b: Get the products with the largest sales percentage of a brand in a time period
go
create or alter procedure getTopDealsOfBrand
		@brand	nvarchar(100),
		@StartTime date,
		@EndTime date
as
begin
	select MaxDeal.manufacture, SanPham.ID as ID_Prod, ProdName, TimeStart, TimeEnd, PromoLevel
	from (select manufacture, MAX(CTKM_SanPham.PromoLevel) as maxRate
			from SanPham, CTKM_SanPham, SanPham_ApDung_CTKM
			where SanPham.ID = SanPham_ApDung_CTKM.ID_Prod 
					and SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID
					and @StartTime <= CTKM_SanPham.TimeStart
					and CTKM_SanPham.TimeStart <= @EndTime
			group by manufacture
			having manufacture = @brand) as MaxDeal, SanPham, SanPham_ApDung_CTKM, CTKM_SanPham
	where SanPham.ID = SanPham_ApDung_CTKM.ID_Prod and
		  SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID and
		  MaxDeal.manufacture = SanPham.manufacture and
		  MaxDeal.maxRate = CTKM_SanPham.PromoLevel
	order by CTKM_SanPham.TimeStart

end

/*-----------------------------------------------------------------------------------------------------------------*/
--Ex4a

--Tính có bao nhiêu món hàng đc bán trong đợt khuyến mãi (nhập ID hàng + ID khuyến mãi)
go
create or alter function getSoldSalesItem (@ID_Prod char(9), @ID_Ad char(9))
returns int
as
begin
	if (not exists(select * from CTKM_SanPham where ID = @ID_Ad))
	begin
		return cast('No sales event with ID: ' + @ID_Ad as INT);
	end

	if (not exists(select * from SanPham where ID = @ID_Prod))
	begin
		return cast('No item with ID: ' + @ID_Prod as INT)
	end

	if (not exists(select * from SanPham_ApDung_CTKM where ID_Ad = @ID_Ad and ID_Prod = @ID_Prod))
	begin
		return cast('Sales event ' + @ID_Ad + ' does not apply for product ' + @ID_Prod as INT) 
	end
	declare @total int;
	declare @start date, @end date;

	select @start = TimeStart, @end = TimeEnd
	from CTKM_SanPham
	where ID = @ID_Ad

	declare BillCursor cursor
	for select SanPham_Thuoc_DonHang.ID_Prod as ID_Prod, DonHang.TimeCreated, SanPham_Thuoc_DonHang.Quantity
	from DonHang, SanPham_Thuoc_DonHang 
	where DonHang.ID = SanPham_Thuoc_DonHang.ID_Order

	declare @soldTime date, @curProdId char(9), @quantity int
	open BillCursor

	fetch next from BillCursor
	into @curProdId, @soldTime, @quantity

	set @total = 0;

	while @@FETCH_STATUS = 0
	begin
		if (@start <= @soldTime and @soldTime <= @end and @curProdId = @ID_Prod)
		begin
			set @total = @total + @quantity
		end

		fetch next from BillCursor
		into @curProdId, @soldTime, @quantity
	end
	return @total;
end
go

select dbo.getSoldSalesItem('PKCH00002', 'KMSP00001') as total

--Ex4b
-- Tim chuong trinh khuyen mai co ti le khuyen mai cao nhat cua 1 mat hang o thoi diem hien tai
go
create or alter function getBestSale (@ID_Prod char(9))
returns @result table(ID_Ad char(9), Rate int)
as
begin
	if (not exists(select * from SanPham where ID = @ID_Prod))
	begin
		insert into @result values (NULL, cast('No item with ID: ' + @ID_Prod as int))
		return
	end

	if (not exists(select * from SanPham_ApDung_CTKM where ID_Prod = @ID_Prod))
	begin
		insert into @result values (NULL, cast('There is no sale event for product: ' + @ID_Prod as INT) )
		return
	end

	declare @today date;
	set @today = GETDATE();

	insert into @result
	select ID_Ad, PromoLevel
	from CTKM_SanPham, SanPham_ApDung_CTKM
	where SanPham_ApDung_CTKM.ID_Prod = @ID_Prod 
			and SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID
			and CTKM_SanPham.TimeStart <= @today
			and CTKM_SanPham.TimeEnd >= @today
			and PromoLevel = (	select MAX(PromoLevel)
								from CTKM_SanPham, SanPham_ApDung_CTKM
								where SanPham_ApDung_CTKM.ID_Prod = @ID_Prod 
									and SanPham_ApDung_CTKM.ID_Ad = CTKM_SanPham.ID
									and CTKM_SanPham.TimeStart <= @today
									and CTKM_SanPham.TimeEnd >= @today)
	return
end
go
