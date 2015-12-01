module Conjur::DSL2::Facts

  # This fact indicates that a record (variable, user, etc.) exists
  class GenericRecordExists < Base
    kind :exists
    attributes :kind, :id, :owner

    def initialize kind, id, owner
      @kind, @id, @owner = kind, id, owner
    end
  end

  class UserHasUserIdNumber < Base
    kind :user_has_uid_number
    attributes :user_id, :uidnumber

    def initialize user_id, uidnumber
      @user_id, @uidnumber = user_id, uidnumber
    end
  end

  class GroupHasGroupIdNumber < Base
    kind :group_has_gid_number
    attributes :group_id, :
  end
end
