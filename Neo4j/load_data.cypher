1. Tạo ràng buộc (constraints) đảm bảo tính duy nhất của các ID
    CREATE CONSTRAINT user_id_unique IF NOT EXISTS
    FOR (u:User)
    REQUIRE u.id IS UNIQUE;
    CREATE CONSTRAINT team_id_unique IF NOT EXISTS
    FOR (t:Team)
    REQUIRE t.id IS UNIQUE;
    CREATE CONSTRAINT team_chat_session_id_unique IF NOT EXISTS
    FOR (c:TeamChatSession)
    REQUIRE c.id IS UNIQUE;
    CREATE CONSTRAINT chat_item_id_unique IF NOT EXISTS
    FOR (i:ChatItem)
    REQUIRE i.id IS UNIQUE;

2. Tạo quan hệ người dùng tạo phiên trò chuyện và phiên trò chuyện thuộc nhóm
    LOAD CSV FROM "file:///chat_create_team_chat.csv" AS row
    MERGE (u:User {id: toInteger(row[0])})
    MERGE (t:Team {id: toInteger(row[1])}) 
    MERGE (c:TeamChatSession {id: toInt(row[2])})
    MERGE (u)-[:CreatesSession{timeStamp: row[3]}]->(c)
    MERGE (c)-[:OwnedBy{timeStamp: row[3]}]->(t)

3. Tạo quan hệ người dùng gửi tin nhắn và tin nhắn thuộc phiên trò chuyện.
    LOAD CSV FROM "file:///chat_item_team_chat.csv" AS row
    MERGE (u:User {id: toInteger(row[0])})
    MERGE (t:TeamChatSession {id: toInteger(row[1])})
    MERGE (c:ChatItem {id: toInteger(row[2])})
    MERGE (u)-[:CreatesChat{timeStamp: row[3]}]->(c)
    MERGE (c)-[:PartOf{timeStamp: row[3]}]->(t)

4. Biểu diễn người dùng tham gia phiên trò chuyện.
    LOAD CSV FROM "file:///chat_join_team_chat.csv" AS row
    MERGE (u:User {id: toInteger(row[0])})
    MERGE (c:TeamChatSession {id: toInteger(row[1])})
    MERGE (u)-[:Joins{timeStamp: row[2]}]->(c)

5. Biểu diễn người dùng rời khỏi phiên trò chuyện.
    LOAD CSV FROM "file:///chat_leave_team_chat.csv" AS row
    MERGE (u:User {id: toInteger(row[0])})
    MERGE (c:TeamChatSession {id: toInteger(row[1])})
    MERGE (u)-[:Leaves{timeStamp: row[2]}]->(c)

6. Biểu diễn tin nhắn đề cập đến người dùng.
    LOAD CSV FROM "file:///chat_mention_team_chat.csv" AS row
    MERGE (c:ChatItem {id: toInteger(row[0])})
    MERGE (u:User {id: toInteger(row[1])})
    MERGE (c)-[:Mentioned{timeStamp: row[2]}]->(u)

7. Biểu diễn phản hồi giữa các tin nhắn.
    LOAD CSV FROM "file:///chat_respond_team_chat.csv" AS row
    MERGE (c1:ChatItem {id: toInteger(row[0])})
    MERGE (c2:ChatItem {id: toInteger(row[1])})
    MERGE (c1)-[:RespondedTo {timeStamp: row[2]}]->(c2)
