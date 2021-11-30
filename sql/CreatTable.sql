drop database db_a2
create database db_a2;
go

use db_a2;
create table KhachHang (
	ID			char(9)			not null,
	Username	nvarchar(100)	not null,
	Passwd		nvarchar(100)	not null,
	Phone		nvarchar(100)	not null,
	Fname		nvarchar(100)	not null,
	Lname		nvarchar(100)	not null,
	Email		nvarchar(100),
	Bdate		date,
	IdNum		nvarchar(100)	not null,
	FamScore	int,
	primary key (ID)
);
go
 
create table GioiThieu (
	IDRef		char(9),
	ID			char(9)			not null,
	primary key (ID)
);
go
 
create table DonHang (
	ID			char(9)			not null,
	TimeCreated	date			not null,
	SumPrices	int				not null,
	ID_Customer	char(9),
	ID_Employee char(9),
	ID_Ad		char(9),
	primary key (ID)
);
go
 
create table CTKM_DonHang (
	ID			char(9)			not null,
	TimeStart	date			not null,
	TimeEnd		date			not null,
	PromoLevel	int				not null,
	Condition	INT,
	primary key (ID)
);
go
 
create table SanPham_Thuoc_DonHang (
	ID_Order	char(9)		not null,
	ID_Prod		char(9)		not null,
	Price		int			not null,
	Quantity	int			not null,
	primary key (ID_Order, ID_Prod)
);
go
 
create table NguoiThan (
	ID_Employee	char(9)			not null,
	Fname		nvarchar(100)	not null,
	Lname		nvarchar(100)	not null,
	Addr		nvarchar(100),
	Phone		nvarchar(100)	not null,
	Relation	nvarchar(100),
	unique (Fname, Lname),
	primary key (ID_Employee, Fname, Lname)
);
go
 
create table NhanVien (
	ID			char(9)			not null,
	Username	nvarchar(100)	not null,
	Passwd		nvarchar(100)	not null,
	IdNum		nvarchar(100)	not null,
	Phone		nvarchar(100)	not null,
	Salary		int,
	Bdate		date			not null,
	Fname		nvarchar(100)	not null,
	Lname		nvarchar(100)	not null,
	Email		nvarchar(100)	not null,
	Addr		nvarchar(100),
	ID_branch	char(9)			not null,
	primary key (ID)
);
go
 
create table ChiNhanh_Ban_SanPham (
	ID_Prod		char(9)		not null,
	ID_Branch	char(9)		not null,
	Quantity    int         not null,
	primary key (ID_Prod, ID_Branch)
);
go
 
create table ChiNhanh (
	ID			char(9)			not null,
	BranchName	nvarchar(100)	not null,
	Addr		nvarchar(100),
	ID_Manager	char(9),
	primary key (ID)
);
go
 
create table SDTChiNhanh (
	ID_Branch	char(9)			not null,
	Phone		nvarchar(100)	not null,
	primary key (ID_Branch, Phone)
);
go
 
CREATE TABLE SanPham (
    ID				CHAR(9)         NOT NULL,
    ProdName		nvarchar(100)   NOT NULL,
    PriceIn			INT,
    Price			INT,
    Insurance		INT,
	TotalQuantity    int			not null,
    Other			nvarchar(100),
    ProdType		nvarchar(100),
    manufacture		nvarchar(100),
	Available		bit				NOT NULL,
    PRIMARY KEY (ID)
);
go

create table HangSanXuat (
	ManuName	nvarchar(100)	not null,
	Addr		nvarchar(100),
	Phone		nvarchar(100),
	primary key (ManuName)
);
go
 
create table CTKM_SanPham (
	ID			char(9)		not null,
	TimeStart	date		not null,
	TimeEnd		date		not null,
	PromoLevel	int			not null,
	primary key (ID)
);
go
 
create table SanPham_ApDung_CTKM (
	ID_Prod		char(9)		not null,
	ID_Ad		char(9)		not null,
	primary key (ID_Prod, ID_Ad)
);
go
 
CREATE TABLE ThietBiDienTu (
    ID          CHAR(9)     NOT NULL,
    Battery     nvarchar(100),
    DateRelease DATE,
    Screen      nvarchar(100),
    RAM         nvarchar(100),
    DeviceType  nvarchar(100),
    PRIMARY KEY (ID)
);
go
 
create table PhuKien (
	ID			char(9)		not null,
	Connection	nvarchar(100),
	AccsoryType nvarchar(100),
	primary key (ID)
);
go
 
create table TaiNghe (
	ID			char(9)		not null,
	HPhoneType	nvarchar(100),
	Battery		nvarchar(100),
	primary key (ID)
);
go
 
create table Chuot (
	ID			char(9)		not null,
	DPI			nvarchar(100),
	primary key (ID)
);
go
 
create table Laptop (
	ID			char(9)		not null,
	CPU			nvarchar(100),
	GPU			nvarchar(100),
	HardDisk	nvarchar(100),
	primary key (ID)
);
go
 
create table DienThoai (
	ID			char(9)		not null,
	Chip		nvarchar(100),
	Camera		nvarchar(100),
	SIM			nvarchar(100),
	InDisk		nvarchar(100),
	primary key (ID)
);
go
 
create table MayTinhBang (
	ID			char(9)		not null,
	Chip		nvarchar(100),
	Camera		nvarchar(100),
	InDisk		nvarchar(100),
	primary key (ID)
);
go

create index idSanPham on SanPham (Price, PriceIn, Insurance, TotalQuantity)