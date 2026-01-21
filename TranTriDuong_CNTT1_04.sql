create database db_ktm;
use db_ktm;

create table readers(
	reader_id int primary key auto_increment,
    full_name varchar(50) not null,
    email varchar(255) unique not null,
    phone_number varchar(50) unique not null,
    created_at date default (current_date())
);

create table membership_details(
	card_number varchar(20) primary key,
    reader_id int not null unique,
    foreign key(reader_id) references readers(reader_id),
    rank_membership enum('Standard', 'VIP'),
    expiry_date date,
    citizen_id varchar(50) not null unique
);

create table categories(
	category_id int auto_increment primary key,
    category_name varchar(30) unique not null,
    description_category text
);

create table books(
	book_id int auto_increment primary key,
    title varchar(100) not null,
    author varchar(100) not null,
    category_id int not null,
    foreign key(category_id) references categories(category_id),
    price int not null check(price > 0),
stock_quantity int not null check(stock_quantity >= 0)

);


create table loan_records(
	loan_id int primary key,
    reader_id int not null,
    foreign key(reader_id) references readers(reader_id),
    book_id int not null,
    foreign key(book_id) references books(book_id),
    borrow_date date,
    due_date date,
    return_date date
);

alter table loan_records
add constraint fk_due_date_borrow_date check(due_date > borrow_date);

insert into readers (full_name,email,phone_number,created_at)
values ('Nguyen Van A','anv@gmail.com','901234567','2022-1-15'),
	('Tran Thi B','btt@gmail.com','912345678','2022-5-20'),
	('Le Van C','cle@yahoo.com','922334455','2023-2-10'),
	('Pham Minh D','dpham@hotmail.com','933445566','2023-11-5'),
	('Hoang Anh E','ehoang@gmail.com','944556677','2024-1-12');
    
insert into membership_details
values('CARD-001',1,'Standard','2025-1-15','123456789'),
	('CARD-002',2,'VIP','2025-5-20','234567890'),
    ('CARD-003',3,'Standard','2024-2-10','345678901'),
    ('CARD-004',4,'VIP','2025-11-5','456789012'),
    ('CARD-005',5,'Standard','2026-1-12','567890123');
    
insert into categories
values(1,'IT','Sách về công nghệ thông tin và lập trình'),
	(2,'Kinh Te','Sách kinh doanh, tài chính, khởi nghiệp'),
    (3,'Van Hoc','Tiểu thuyết, truyện ngắn, thơ'),
    (4,'Ngoai Ngu','Sách học tiếng Anh, Nhật, Hàn'),
    (5,'Lich Su','Sách nghiên cứu lịch sử, văn hóa');

insert into books 
values(1,'Clean Code','Robert C. Martin',1,450000,10),
	(2,'Dac Nhan Tam','Dale Carnegie',2,150000,50),
	(3,'Harry Potter 1','J.K. Rowling',3,250000,5),
	(4,'IELTS Reading','Cambridge',4,180000,0),
	(5,'Dai Viet Su Ky','Le Van Huu',5,300000,20);

insert into loan_records
values (101,1,1,'2023-11-15','2023-11-22','2023-11-20'),
	(102,2,2,'2023-12-1','2023-12-8','2023-12-5'),
	(103,3,3,'2024-1-10','2024-1-17',null),
	(104,4,4,'2023-5-20','2023-5-27',null),
	(105,5,5,'2024-1-18','2024-1-25',null);

  -- - Gia hạn thêm 7 ngày cho due_date (Ngày dự kiến trả)
--   đối với tất cả các phiếu mượn sách thuộc danh mục 'Van Hoc' mà chưa được trả (return_date IS NULL).
update loan_records
set due_date = due_date + interval 7 day
where return_date is null
and book_id in (
    select b.book_id
    from books b
    join categories c on b.category_id = c.category_id
    where c.category_name = 'Van Hoc'
);
  -- - Xóa các hồ sơ mượn trả (Loan_Records)
-- đã hoàn tất trả sách (return_date KHÔNG NULL) và có ngày mượn trước tháng 10/2023.
delete from loan_records
where return_date is not null
and borrow_date < '2023-10-01';

-- Phan 2
-- cau 1
select b.book_id,b.title,b.price,c.category_name
from books b,categories c
where b.category_id = c.category_id 
	and price >200000 
	and category_name = 'IT';
    
-- cau 2
select reader_id,full_name,email
from readers
where year(created_at) = 2022 and email like '%@gmail.com';

-- cau 3
select * 
from books
order by price desc
limit 5 offset 2;

-- Phan 3
-- cau 1
select l.loan_id, r.full_name, b.title, l.borrow_date, l.return_date
from loan_records l
join readers r on r.reader_id = l.reader_id
join books b on b.book_id = l.book_id
where return_date is null;

-- cau 2
select c.category_name,
		sum(b.stock_quantity) as total_quantity
from categories c 
join books b on c.category_id = b.category_id
group by c.category_name
having sum(b.stock_quantity) > 10;

-- cau 3
select r.full_name
from readers r
join membership_details m on r.reader_id = m.reader_id
where m.rank_membership = 'VIP'
and not exists (
    select 1
    from loan_records l
    join books b on l.book_id = b.book_id
    where l.reader_id = r.reader_id
      and b.price > 300000
);


-- phan 4
-- cau 1
create index idx_loan_dates on loan_records(borrow_date, return_date);
-- cau 2
create view vw_overdue_loans as
select l.loan_id, r.full_name, b.title, l.borrow_date, l.due_date
from loan_records l
join readers r on r.reader_id = l.reader_id
join books b on b.book_id = l.book_id
where return_date is null and date(current_date()) > date(due_date);

-- phan 5
-- cau 1
delimiter ~~

create trigger trg_after_loan_insert
after insert on loan_records
for each row
begin
    update books
    set stock_quantity = stock_quantity - 1
    where book_id = new.book_id
      and stock_quantity > 0;
end ~~

delimiter ;


-- cau 2
delimiter ~~
create trigger trg_prevent_delete_active_reader
before delete on readers
for each row
begin
	if exists (
    select 1
    from loan_records
    where reader_id = old.reader_id
      and return_date is null
    ) then
        signal sqlstate '45000'
        set message_text = 'Khong the xoa doc gia nay';
    end if;
end ~~ 
delimiter ;

-- phan 6
-- cau 1
delimiter ~~
create procedure sp_check_availability(p_book_id int, out p_message text)
begin
	declare num int;
    select stock_quantity into num
    from books
    where book_id = p_book_id;
    
    if num = 0 then set p_message = 'Hết hàng';
    elseif num <= 5 and num > 0 then set p_message = 'Sắp hết';
    else set p_message = 'Còn hàng';
    end if;
end ~~ 
delimiter ;

-- cau 2
delimiter ~~
create procedure sp_return_book_transaction(p_loan_id int)
begin
    declare v_book_id int;
    declare v_return_date date;

	start transaction;

    select book_id, return_date
    into v_book_id, v_return_date
    from loan_records
    where loan_id = p_loan_id
    for update;

    if v_return_date is not null then
        rollback;
        signal sqlstate '45000'
        set message_text = 'Sách đã được trả trước đó';
    else
        update loan_records
        set return_date = current_date()
        where loan_id = p_loan_id;

        update books
        set stock_quantity = stock_quantity + 1
        where book_id = v_book_id;

        commit;
    end if;
end ~~ 
delimiter ;





