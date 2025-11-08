-- Analysis Code
use igg;

-- USER INSIGHTS AND REGISTRATION BEHAVIOR

/*We want to reward our users who have been around the longest.  
Find the 5 oldest users.*/
SELECT * 
FROM users
ORDER BY created_at
LIMIT 5;

/*What day of the week do most users register on?
We need to figure out when to schedule an ad campaign*/
SELECT DATE_FORMAT(created_at,'%W') AS Day_of_the_week, COUNT(*) AS Total_registration
FROM users
GROUP BY 1
ORDER BY 2 DESC;

/*Version 2 - alternate approach using DAYNAME()*/
SELECT 
    DAYNAME(created_at) AS day,
    COUNT(*) AS total
FROM users
GROUP BY day
ORDER BY total DESC;

/*Alternate - month wise registration analysis*/
SELECT 
    MONTHNAME(created_at) AS month_name,
    COUNT(*) AS total_registrations
FROM users
GROUP BY month_name
ORDER BY total_registrations DESC;


-- USER ACTIVITY AND POSTING BEHAVIOR

/*We want to target our inactive users with an email campaign.
Find the users who have never posted a photo*/
SELECT username
FROM users
LEFT JOIN photos ON users.id = photos.user_id
WHERE photos.id IS NULL;

/*Our Investors want to know...
How many times does the average user post?*/
/*total number of photos/total number of users*/
SELECT ROUND((SELECT COUNT(*) FROM photos)/(SELECT COUNT(*) FROM users),2) AS averageuserpost;

/*User ranking by postings higher to lower*/
SELECT u.username, COUNT(p.id) AS No_of_post
FROM users u
JOIN photos p ON u.id = p.user_id
GROUP BY u.id
ORDER BY 2 DESC;

/*Total numbers of users who have posted at least one time */
SELECT COUNT(DISTINCT(users.id)) AS total_number_of_users_with_posts
FROM users
JOIN photos ON users.id = photos.user_id;


-- ENGAGEMENT AND INTERACTION ANALYSIS

/*We're running a new contest to see who can get the most likes on a single photo.
WHO WON??!!*/
SELECT 
    u.username, 
    p.id AS photo_id, 
    p.image_url, 
    COUNT(*) AS total_likes
FROM likes AS l
JOIN photos AS p ON p.id = l.photo_id
JOIN users AS u ON u.id = p.user_id
GROUP BY p.id
ORDER BY total_likes DESC
LIMIT 1;

/*A brand wants to know which hashtags to use in a post
What are the top 5 most commonly used hashtags?*/
SELECT tag_name, COUNT(tag_name) AS total
FROM tags
JOIN photo_tags ON tags.id = photo_tags.tag_id
GROUP BY tags.id
ORDER BY total DESC
LIMIT 5;

/*We have a small problem with bots on our site...
Find users who have liked every single photo on the site*/
SELECT u.id, u.username, COUNT(u.id) AS total_likes_by_user
FROM users u
JOIN likes l ON u.id = l.user_id
GROUP BY u.id
HAVING total_likes_by_user = (SELECT COUNT(*) FROM photos);

/*We also have a problem with celebrities
Find users who have never commented on a photo*/
SELECT u.username
FROM users AS u
LEFT JOIN comments AS c ON u.id = c.user_id
WHERE c.id IS NULL;

/*Each user's total comment count*/
SELECT u.username, COUNT(c.id) AS each_comment_count
FROM users u
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.username
ORDER BY each_comment_count;


-- BOT VS CELEBRITY BEHAVIOR ANALYSIS

/*Are we overrun with bots and celebrity accounts?
Find the percentage of our users who have either never commented on a photo or have commented on every photo*/
SELECT 
    tableA.total_A AS 'Number of Users who never commented',
    ROUND((tableA.total_A / (SELECT COUNT(*) FROM users)) * 100, 2) AS '% Never Commented',
    tableB.total_B AS 'Number of Users who liked every photo',
    ROUND((tableB.total_B / (SELECT COUNT(*) FROM users)) * 100, 2) AS '% Liked Every Photo'
FROM
(
    SELECT COUNT(*) AS total_A
    FROM (
        SELECT u.id
        FROM users AS u
        LEFT JOIN comments AS c ON u.id = c.user_id
        GROUP BY u.id
        HAVING COUNT(c.id) = 0
    ) AS inactive_users
) AS tableA
JOIN
(
    SELECT COUNT(*) AS total_B
    FROM (
        SELECT u.id
        FROM users AS u
        JOIN likes AS l ON u.id = l.user_id
        GROUP BY u.id
        HAVING COUNT(l.photo_id) = (SELECT COUNT(*) FROM photos)
    ) AS overactive_users
) AS tableB;

-- FOLLOWER AND NETWORK RELATIONSHIPS
/*Find the top 3 users with the highest follower count.*/
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(f.follower_id) AS follower_count
FROM users u
LEFT JOIN follows f ON u.id = f.followee_id
GROUP BY u.id, u.username
ORDER BY follower_count DESC
LIMIT 3;

/*Identify users who follow more people than follow them back.*/
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT f1.followee_id) AS following_count,
    COUNT(DISTINCT f2.follower_id) AS follower_count
FROM users u
LEFT JOIN follows f1 ON u.id = f1.follower_id
LEFT JOIN follows f2 ON u.id = f2.followee_id
GROUP BY u.id, u.username
HAVING following_count > follower_count;

/*Remove follows where follower and followee are the same user.*/
DELETE FROM follows
WHERE follower_id = followee_id;


-- CONTENT ENGAGEMENT ANALYSIS
/*Determine the percentage of photos with at least one like.*/
SELECT (COUNT(DISTINCT l.photo_id) * 100.0 / COUNT(DISTINCT p.id)) AS percentage_with_likes
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id;

/*List photos that have never received a comment or a like.*/
SELECT p.id, p.image_url
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
WHERE l.photo_id IS NULL AND c.photo_id IS NULL;

/*Find users who have liked their own photos.*/
SELECT u.username, p.id AS photo_id
FROM photos p
JOIN likes l ON p.id = l.photo_id
JOIN users u ON u.id = p.user_id
WHERE p.user_id = l.user_id;

/*Show the ratio of comments to likes for each photo.*/
SELECT 
    p.id AS photo_id,
    p.image_url,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT l.id) AS total_likes,
    CASE 
        WHEN COUNT(DISTINCT l.id) = 0 THEN 0
        ELSE ROUND(COUNT(DISTINCT c.id) / COUNT(DISTINCT l.id), 2)
    END AS comment_like_ratio
FROM photos p
LEFT JOIN comments c ON p.id = c.photo_id
LEFT JOIN likes l ON p.id = l.photo_id
GROUP BY p.id, p.image_url;


-- PHOTO POPULARITY METRICS
/*Create a new table photo_popularity with columns photo_id, likes_count, comments_count.*/
CREATE TABLE photo_popularity (
    photo_id INT PRIMARY KEY,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    FOREIGN KEY (photo_id) REFERENCES photos(id)
);

/*Populate photo_popularity with existing engagement counts (likes and comments).*/
INSERT INTO photo_popularity (photo_id, likes_count, comments_count)
SELECT 
    p.id AS photo_id,
    COUNT(DISTINCT l.user_id) AS likes_count,
    COUNT(DISTINCT c.id) AS comments_count
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY p.id;

/*View top performing photos by total engagement.*/
SELECT * 
FROM photo_popularity 
ORDER BY (likes_count + comments_count) DESC 
LIMIT 10;


-- AVERAGE ENGAGEMENT ANALYSIS
/*Calculate the average number of likes each user’s photos receive.*/
SELECT 
    u.id AS user_id,
    u.username,
    ROUND(AVG(pl.like_count), 2) AS avg_likes_per_photo
FROM users u
JOIN (
    SELECT 
        p.user_id,
        COUNT(l.user_id) AS like_count
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY p.id
) AS pl
ON u.id = pl.user_id
GROUP BY u.id, u.username
ORDER BY avg_likes_per_photo DESC;


-- COMMENTING BEHAVIOR
/*Identify users who commented on all the photos they liked.*/
SELECT 
    l.user_id,
    u.username
FROM likes l
JOIN users u ON u.id = l.user_id
LEFT JOIN comments c ON l.user_id = c.user_id 
    AND l.photo_id = c.photo_id
GROUP BY l.user_id, u.username
HAVING COUNT(DISTINCT l.photo_id) = COUNT(DISTINCT c.photo_id);


-- TAG INSIGHTS
/*Find tags that have been used on every photo.*/
SELECT 
    t.id AS tag_id,
    t.tag_name
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.id, t.tag_name
HAVING COUNT(DISTINCT pt.photo_id) = (SELECT COUNT(DISTINCT id) FROM photos);

/*Analyze pairs of tags that appear together most frequently.*/
SELECT 
    t1.tag_name AS tag1,
    t2.tag_name AS tag2,
    COUNT(DISTINCT pt1.photo_id) AS photos_together
FROM photo_tags pt1
JOIN photo_tags pt2 ON pt1.photo_id = pt2.photo_id AND pt1.tag_id < pt2.tag_id
JOIN tags t1 ON t1.id = pt1.tag_id
JOIN tags t2 ON t2.id = pt2.tag_id
GROUP BY t1.tag_name, t2.tag_name
ORDER BY photos_together DESC
LIMIT 10;


-- TEMPORAL INSIGHTS
/*Show total likes given per month in 2017.*/
SELECT 
    MONTHNAME(created_at) AS month_name,
    COUNT(*) AS total_likes
FROM likes
WHERE YEAR(created_at) = 2017
GROUP BY MONTH(created_at), MONTHNAME(created_at)
ORDER BY MONTH(created_at);

/*Compare the number of photo posts on weekdays vs weekends.*/
SELECT 
    CASE 
        WHEN DAYOFWEEK(created_dat) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_posts
FROM photos
GROUP BY day_type;


-- HIGH ENGAGEMENT USER SEGMENTATION
/*Create a view active_users showing users with ≥10 posts and ≥50 likes received.*/
CREATE VIEW active_users AS
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.user_id) AS total_likes_received
FROM users u
JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
GROUP BY u.id, u.username
HAVING total_posts >= 10
   AND total_likes_received >= 50;

/*View the high-engagement user list.*/
SELECT * FROM active_users;


-- USER ENGAGEMENT METRICS SUMMARY
/*Generate a combined user engagement summary showing posts, likes, and comments.*/
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.user_id) AS total_likes_received,
    COUNT(DISTINCT c.id) AS total_comments_received
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY total_posts + total_likes_received + total_comments_received DESC;

