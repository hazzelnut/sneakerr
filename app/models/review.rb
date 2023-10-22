class Review < ApplicationRecord
  belongs_to :user
  belongs_to :sneaker

  validates :body, presence: true

  after_destroy_commit -> {
    broadcast_remove_to [sneaker, :reviews], target: self
    broadcast_update_to [sneaker, :reviews],
      target: dom_id(sneaker, :review_count),
      html: sneaker.reviews.count
  }

  # No context to the session when broadcasting
  # As in, when we render the partial '/reviews/review', we won't have the edit and delete buttons
  # until we refresh the page. There's probably workarounds, but the trade-off here is we won't
  # get those options right after creation
  # Also, 'broadcast_append_later_to' makes it an async call instaed of sync
  # There's a rendering step involve with all these updates which can slow down execution
  # Making it async allows the task to update to not be tied to one request thread
  after_create_commit -> {
    broadcast_append_later_to [sneaker, :reviews],
    partial: 'reviews/simple_review',
    target: dom_id(sneaker, :reviews),
    locals: { review: self }

    broadcast_update_later_to [sneaker, :reviews],
      target: dom_id(sneaker, :review_count),
      html: sneaker.reviews.count
  }

  after_update_commit -> {
    broadcast_replace_later_to [sneaker, :reviews],
    partial: 'reviews/simple_review',
    locals: { review: self }
  }
end
