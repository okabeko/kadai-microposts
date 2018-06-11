class User < ApplicationRecord
  before_save { self.email.downcase! }
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  
  has_many :microposts
  
  # relationships（中間テーブル）との一対多の関係
  # user.relationshipとするとRelationshipを取得できる、が、あくまで中間テーブルのデータ
  has_many :relationships
  # followingsの命名によりreilationships経由で中間テーブルの先のモデルを参照する。
  has_many :followings, through: :relationships, source: :follow
  # follow_idを用いてRelationshipからUserを参照（逆方向はRailsの命名規則に従っていないためforeign_keyの設定が必要）
  has_many :reverses_of_relationship, class_name: 'Relationship', foreign_key: 'follow_id'
  has_many :followers, through: :reverses_of_relationship, source: :user
  
  def follow(other_user)
    # フォロー対象が自分自身では無いかどうかのチェック
    unless self == other_user
      self.relationships.find_or_create_by(follow_id: other_user.id)
    end
  end
  
  def unfollow(other_user)
    # すでにフォローしているかどうか
    relationship = self.relationships.find_by(follow_id: other_user.id)
    # relationshipが存在したらdestroy
    relationship.destroy if relationship
  end
  
  def following?(other_user)
    self.followings.include?(other_user)
  end
  
  def feed_microposts
    Micropost.where(user_id: self.following_ids + [self.id])
  end
    
  has_many :likes
  has_many :like_microposts, through: :likes, source: :micropost
  
  def like(micropost)
    self.likes.find_or_create_by(micropost_id: micropost.id)
  end
  
  def unlike(micropost)
    like = self.likes.find_by(micropost_id: micropost.id)
    like.destroy if like
  end
  
  def like?(micropost)
    self.like_microposts.include?(micropost)
  end
end
