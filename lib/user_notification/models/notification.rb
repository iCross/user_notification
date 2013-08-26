module UserNotification
  class Notification < inherit_orm("Notification")

    def mark_as_read_for!(recipient)
      self.notifyings.where(recipient: recipient).update_all(:read, true)
    end

    def read_by?(recipient)
      self.notifyings.where(recipient: recipient).first.read?
    end

  end
end
