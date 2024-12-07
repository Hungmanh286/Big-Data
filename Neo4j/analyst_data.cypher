I, phân tích đoạn chat dài nhất
1, Create relation Response giữa các ChatItem
    LOAD CSV FROM "file:///chat_respond_team_chat.csv" AS row
    MATCH (c1:ChatItem {id: TOINTEGER(row[0])})
    MATCH (c2:ChatItem {id: TOINTEGER(row[1])})
    MERGE (c1)-[:RespondedTo {timeStamp: row[2]}]->(c2)

2, Độ dài đoạn chat dài nhất     
    MATCH p = (i1)-[:RespondedTo*]->(i2)
    RETURN LENGTH(p)
    ORDER BY LENGTH(p) DESC LIMIT 1

3, Số người tham gia đoạn chat
    MATCH p = (i1)-[:ResponseTo*]->(i2)
    WHERE LENGTH(p) = 9
    WITH p
    MATCH (u)-[:CreateChat]->(i)
    WHERE i IN NODES(p)
    RETURN COUNT(DISTINCT u)

II, Phân tích mối quan hệ giữa người hoạt động nhiều và nhóm hoạt động nhiều
4, Top 10 người dùng nhắn nhiều nhất
    MATCH (u)-[:CreateChat*]->(i)
    RETURN u.id, COUNT(i)
    ORDER BY COUNT(i) DESC LIMIT 10

5, Top 10 team nhắn nhiều nhất
    MATCH (i)-[:PartOf*]->(c)-[:OwnedBy*]->(t)
    RETURN t.id, COUNT(c)
    ORDER BY COUNT(c) DESC LIMIT 10

III, Phân tích hoạt động của nhóm người dùng
6, Creat relation InteractsWith:
    MATCH (u1:User)-[:CreateChat]-(i:ChatItem)-[:Mentioned]->(u2:User)
    MERGE (u1)-[:InteractsWith]->(u2)
    WITH u1, u2
    MATCH (u1:User)-[:CreateChat]->(i1:ChatItem)-[:ResponseTo]->(i2:ChatItem)<-[:CreateChat]-(u2:User)
    MERGE (u1)-[:InteractsWith]->(u2)
    WITH u1
    MATCH (u1)-[r:InteractsWith]->(u1)
    DELETE r
7, Neighbors của user 394 và 2011
    MATCH (u1:User {id: 394})-[r:InteractsWith]-(u2:User)
    WITH u1, COLLECT(DISTINCT u2.id) AS Neighbors
RETURN u1.id, Neighbors

IV, Phát hiện cộng đồng
8, Tạo graph để phân tích bằng GDS (Grap Data Science)
    CALL gds.graph.project(
    'newChatGraph',
    ['User', 'TeamChatSession'],
    {Mentioned: {orientation: 'NATURAL'}, CreatesChat: {orientation: 'NATURAL'}, Joins: {orientation: 'NATURAL'}}
    )
9, thuật toán Label Propagation để phát hiện cộng đồng trong GDS
    CALL gds.labelPropagation.stream('newChatGraph')
    YIELD nodeId, communityId
    WITH gds.util.asNode(nodeId) AS node, communityId
    RETURN node.id AS userId, communityId
    ORDER BY communityId, userId
10, Tạo project để phân tích bằng gds
    CALL gds.graph.project('userGraph', ['User'], {InteractsWith: {}})
11, Thuật toán pageRank để đánh giá các User thông qua tương tác giữa các Users
    CALL gds.pageRank.stream('userGraph', {
    maxIterations: 100,
    dampingFactor: 0.85
    })
    YIELD nodeId, score
    RETURN gds.util.asNode(nodeId).id AS userID, score
    ORDER BY score DESC LIMIT 3
12, Liệt kê điểm số của những người tương tác với User có điểm cao nhất
    CALL gds.pageRank.stream('userGraph', {
    maxIterations: 100
    })
    YIELD nodeId, score
    WITH gds.util.asNode(nodeId) AS topUser, score
    ORDER BY score DESC
    LIMIT 1
    WITH topUser
    MATCH (topUser)-[:InteractsWith]-(otherUser: User)
    WITH DISTINCT otherUser, topUser
    CALL gds.pageRank.stream('userGraph', {
        maxIterations: 100
    })
    YIELD nodeId, score
    WHERE id(otherUser) = nodeId
    WITH topUser, otherUser, score
    RETURN topUser.id, otherUser.id, score
    ORDER BY score DESC
13, Liệt kê điểm số của những người tương tác với User có điểm cao số 2
    CALL gds.pageRank.stream('userGraph', {
    maxIterations: 100
    })
    YIELD nodeId, score
    WITH gds.util.asNode(nodeId) AS topUser, score
    ORDER BY score DESC
    SKIP 1
    LIMIT 1
    WITH topUser
    MATCH (topUser)-[:InteractsWith]-(otherUser: User)
    WITH DISTINCT otherUser, topUser
    CALL gds.pageRank.stream('userGraph', {
        maxIterations: 100
    })
    YIELD nodeId, score
    WHERE id(otherUser) = nodeId
    WITH topUser, otherUser, score
    RETURN topUser.id, otherUser.id, score
    ORDER BY score DESC
14, Tính trung bình điểm số của những người tương tác với topUser
    CALL gds.pageRank.stream('userGraph', {
        maxIterations: 100
    })
    YIELD nodeId, score
    WITH gds.util.asNode(nodeId) AS topUser, score
    ORDER BY score DESC
    LIMIT 2
    WITH topUser
    MATCH (topUser)-[r:InteractsWith]-(otherUser: User)
    WITH DISTINCT otherUser, topUser, r
    CALL gds.pageRank.stream('userGraph', {
        maxIterations: 100
    })
    YIELD nodeId, score
    WHERE id(otherUser) = nodeId
    WITH topUser, score, r
    RETURN topUser.id AS userId, AVG(score) AS avgPageRankScore, count(r) AS numInteractsWith
