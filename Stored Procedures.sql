DELIMITER //

CREATE PROCEDURE CheckBooking(IN TargetDate DATE, IN TargetTable INT)
BEGIN
    DECLARE TableStatus INT;
    
    -- Check if a record exists for the given date and table
    SELECT COUNT(*) INTO TableStatus
    FROM Bookings
    WHERE BookingDate = TargetDate AND TableNumber = TargetTable;
    
    -- Evaluate the status and return a meaningful state message
    IF TableStatus > 0 THEN
        SELECT CONCAT('Table ', TargetTable, ' is already booked on ', TargetDate) AS 'Booking Status';
    ELSE
        SELECT CONCAT('Table ', TargetTable, ' is available for reservation on ', TargetDate) AS 'Booking Status';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE AddValidBooking(IN NewBookingID INT, IN NewBookingDate DATE, IN NewTableNumber INT, IN NewCustomerID INT)
BEGIN
    DECLARE SlotConflict INT DEFAULT 0;
    
    -- Start the atomic transaction block
    START TRANSACTION;
    
    -- Insert the new booking attempt
    INSERT INTO Bookings (BookingID, BookingDate, TableNumber, CustomerID)
    VALUES (NewBookingID, NewBookingDate, NewTableNumber, NewCustomerID);
    
    -- Check if that table number is now duplicated for the same date
    SELECT COUNT(*) INTO SlotConflict
    FROM Bookings
    WHERE BookingDate = NewBookingDate AND TableNumber = NewTableNumber;
    
    -- If the count is greater than 1, a conflict occurred; roll back changes
    IF SlotConflict > 1 THEN
        ROLLBACK;
        SELECT CONCAT('Table ', NewTableNumber, ' is already booked - Booking cancelled and rolled back.') AS 'Booking Status';
    ELSE
        COMMIT;
        SELECT CONCAT('Booking ', NewBookingID, ' successfully confirmed and committed.') AS 'Booking Status';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE AddBooking(IN NewBookingID INT, IN NewCustomerID INT, IN NewTableNumber INT, IN NewBookingDate DATE)
BEGIN
    INSERT INTO Bookings (BookingID, CustomerID, TableNumber, BookingDate)
    VALUES (NewBookingID, NewCustomerID, NewTableNumber, NewBookingDate);
    
    SELECT 'New booking successfully recorded.' AS 'Confirmation';
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE UpdateBooking(IN TargetBookingID INT, IN NewBookingDate DATE)
BEGIN
    UPDATE Bookings
    SET BookingDate = NewBookingDate
    WHERE BookingID = TargetBookingID;
    
    SELECT CONCAT('Booking ', TargetBookingID, ' updated to ', NewBookingDate) AS 'Confirmation';
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE CancelBooking(IN TargetBookingID INT)
BEGIN
    DELETE FROM Bookings
    WHERE BookingID = TargetBookingID;
    
    SELECT CONCAT('Booking ', TargetBookingID, ' has been successfully deleted.') AS 'Confirmation';
END //

DELIMITER ;

-- 1. Check if a table is open
CALL CheckBooking('2026-12-25', 5);

-- 2. Test transactional verification logic
CALL AddValidBooking(99, '2026-12-25', 5, 1);

-- 3. Modify an existing assignment record
CALL UpdateBooking(99, '2026-12-26');

-- 4. Clear the testing reservation record
CALL CancelBooking(99);