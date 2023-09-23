DROP TABLE IF EXISTS `food_items`;


-- creating food_items tables


CREATE TABLE `food_items` (
  `item_id` int NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`item_id`)
);


-- Dumping data for table `food_items`


INSERT INTO `food_items` VALUES 
	(121, 'Chicken Dum Biryani', 300),
    (122, 'Chicken Biryani', 280),
    (123, 'Dum Ghost Mutton Biryani', 340),
    (124, 'Mutton Biryani', 320),
    (125, 'Paneer Biryani', 260),
    (126, 'Shahi Special Biryani', 360),
    (127, 'Veg Dum Biryani', 250),
    (128, 'Hyderabadi Dum Biryani', 330),
    (129, 'Gulab Jamun', 70),
    (130, 'Coke', 50),
    (131, 'Mughlai Gravy', 40),
    (132, 'Mint Raita', 30);
    
    
-- Table structure for table `order_tracking`


CREATE TABLE `order_tracking` (
  `order_id` int NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`order_id`)
);


-- Dumping data for table `order_tracking`


INSERT INTO `order_tracking` VALUES (122,'in_transit'),(125,'deliverd');

INSERT INTO `order_tracking` (`order_id`, `status`)
VALUES (400, 'in_transit'), (403, 'deliverd');

DELETE FROM `order_tracking`
WHERE `order_id` IN (122, 125);


-- Table structure for table `orders`


CREATE TABLE `orders` (
  `order_id` int NOT NULL,
  `item_id` int NOT NULL,
  `quantity` int DEFAULT NULL,
  `total_price` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`item_id`),
  KEY `orders_ibfk_1` (`item_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `food_items` (`item_id`)
);


-- Dumping data for table `orders`


INSERT INTO `orders` VALUES (400, 122 , 2 ,360),(403, 125 , 2 ,320);


-- Dumping routines for database 'BOT_BIT'


DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `get_price_for_item`(p_item_name VARCHAR(255)) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_price DECIMAL(10, 2);
    
    -- Check if the item_name exists in the food_items table
    IF (SELECT COUNT(*) FROM food_items WHERE name = p_item_name) > 0 THEN
        -- Retrieve the price for the item
        SELECT price INTO v_price
        FROM food_items
        WHERE name = p_item_name;
        
        RETURN v_price;
    ELSE
        -- Invalid item_name, return -1
        RETURN -1;
    END IF;
END ;;
DELIMITER ;



DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `get_total_order_price`(p_order_id INT) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_total_price DECIMAL(10, 2);
    
    -- Check if the order_id exists in the orders table
    IF (SELECT COUNT(*) FROM orders WHERE order_id = p_order_id) > 0 THEN
        -- Calculate the total price
        SELECT SUM(total_price) INTO v_total_price
        FROM orders
        WHERE order_id = p_order_id;
        
        RETURN v_total_price;
    ELSE
        -- Invalid order_id, return -1
        RETURN -1;
    END IF;
END ;;
DELIMITER ;



DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_order_item`(
  IN p_food_item VARCHAR(255),
  IN p_quantity INT,
  IN p_order_id INT
)
BEGIN
    DECLARE v_item_id INT;
    DECLARE v_price DECIMAL(10, 2);
    DECLARE v_total_price DECIMAL(10, 2);

    -- Get the item_id and price for the food item
    SET v_item_id = (SELECT item_id FROM food_items WHERE name = p_food_item);
    SET v_price = (SELECT get_price_for_item(p_food_item));

    -- Calculate the total price for the order item
    SET v_total_price = v_price * p_quantity;

    -- Insert the order item into the orders table
    INSERT INTO orders (order_id, item_id, quantity, total_price)
    VALUES (p_order_id, v_item_id, p_quantity, v_total_price);
END ;;
DELIMITER ;

