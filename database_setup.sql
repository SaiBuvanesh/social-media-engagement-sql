-- Social Media User Engagement Analytics SQL Project
-- Project by: Sai Buvanesh
-- Description: Modeling social engagement data to explore user behavior, activity trends, and engagement insights.

CREATE DATABASE IF NOT EXISTS igg;
USE igg;

-- users table: stores account info
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- photos table: stores uploaded photos by users
CREATE TABLE photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    image_url VARCHAR(355) NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
);

-- comments table: text comments on photos
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    comment_text VARCHAR(1000) NOT NULL,
    user_id INT NOT NULL,
    photo_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (photo_id) REFERENCES photos(id)
        ON DELETE CASCADE
);

-- likes table: users liking photos
CREATE TABLE likes (
    user_id INT NOT NULL,
    photo_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, photo_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (photo_id) REFERENCES photos(id)
        ON DELETE CASCADE
);

-- follows table: users following other users
CREATE TABLE follows (
    follower_id INT NOT NULL,
    followee_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followee_id),
    FOREIGN KEY (follower_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (followee_id) REFERENCES users(id)
        ON DELETE CASCADE
);

-- tags table: hashtags used on photos
CREATE TABLE tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- photo_tags table: many-to-many relation between photos and tags
CREATE TABLE photo_tags (
    photo_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (photo_id, tag_id),
    FOREIGN KEY (photo_id) REFERENCES photos(id)
        ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id)
        ON DELETE CASCADE
);

-- enable data import if needed
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
-- if OFF, run the above command as admin before import

-- import users
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, username, created_at);

-- import tags
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/tags.csv'
INTO TABLE tags
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, tag_name, created_at);

-- import photos
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/photos.csv'
INTO TABLE photos
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, image_url, user_id, created_at);

-- import photo_tags
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/photo_tags.csv'
INTO TABLE photo_tags
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(photo_id, tag_id);

-- import likes
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/likes.csv'
INTO TABLE likes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(user_id, photo_id, created_at);

-- import follows
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/follows.csv'
INTO TABLE follows
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(follower_id, followee_id, created_at);

-- import comments
LOAD DATA LOCAL INFILE 'C:/Users/Sai Buvanesh/Downloads/IL DSDA/INSTA SQL PROJ/comments.csv'
INTO TABLE comments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, comment_text, user_id, photo_id, created_at);

-- simple validation checks
SELECT COUNT(*) AS duplicate_users FROM users WHERE id IS NULL OR username = '';
SELECT COUNT(*) AS orphan_photos FROM photos WHERE user_id NOT IN (SELECT id FROM users);
SELECT COUNT(*) AS invalid_likes FROM likes WHERE photo_id NOT IN (SELECT id FROM photos);

-- sample select preview
SELECT * FROM users LIMIT 5;
SELECT * FROM photos LIMIT 5;
SELECT * FROM likes LIMIT 5;
