module UserNotification
  class Notification < inherit_orm("Notification")

    def mark_as_read_for!(recipient)
      self.notifings.where(recipient: recipient).update_all(:read, true)
    end

  end
end
