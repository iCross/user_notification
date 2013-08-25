module UserNotification
  class Notification < inherit_orm("Notification")

    def mark_as_read
      self.read = true
    end

    def mark_as_read!
      self.update_attribute(:read, true)
    end

  end
end
