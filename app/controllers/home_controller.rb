class HomeController < ApplicationController
  def index
    unless user_signed_in?
      redirect_to new_user_session_path
    else
      @post = Post.new
      followees_ids = current_user.followees(User).map{|r| r.id}
      followees_ids << current_user.id

      news_feed_query ||= "SELECT activity.* FROM activities activity LEFT JOIN ( SELECT act.post_id, MAX (act.\"id\") AS ID FROM ( SELECT CASE WHEN a1.\"key\" LIKE 'post%' THEN p1.posts_id WHEN a1.\"key\" LIKE 'comment%' THEN c1.post_id WHEN a1.\"key\" LIKE 'like%' THEN l1.post_id END AS post_id, a1.\"id\" FROM activities a1 LEFT JOIN (SELECT ID AS posts_id FROM posts) p1 ON p1.posts_id = a1.trackable_id AND a1.\"key\" LIKE 'post%' LEFT JOIN ( SELECT MAX (ID) AS trackable_id2, post_id FROM comments GROUP BY post_id ) c1 ON c1.trackable_id2 = a1.trackable_id AND a1.\"key\" LIKE 'comment%' LEFT JOIN ( SELECT MAX (ID) AS trackable_id3, likeable_id AS post_id FROM likes GROUP BY likeable_id ) l1 ON l1.trackable_id3 = a1.trackable_id AND a1.\"key\" LIKE 'like%' WHERE p1.posts_id IS NOT NULL OR c1.post_id IS NOT NULL OR l1.post_id IS NOT NULL ORDER BY 1 DESC, 2 DESC ) act GROUP BY 1 ) act2 ON act2.\"id\" = activity.\"id\" WHERE act2.\"id\" IS NOT NULL ORDER BY created_at DESC"

      new_feed_activities ||= PublicActivity::Activity
        .find_by_sql(news_feed_query).map {|r| r.id}

      @activities ||= PublicActivity::Activity.where(id: new_feed_activities).where(owner_id: followees_ids , owner_type: "User")
    end
  end
end

