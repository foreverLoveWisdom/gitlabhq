# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      DiscussionID = ::Types::GlobalIDType[::Discussion]

      authorize :read_note

      implements Types::ResolvableInterface

      field :created_at, Types::TimeType, null: false,
        description: "Timestamp of the discussion's creation."
      field :id, DiscussionID, null: false,
        description: "ID of this discussion."
      field :noteable, Types::NoteableType, null: true,
        description: 'Object which the discussion belongs to.'
      field :notes, Types::Notes::NoteType.connection_type, null: false,
        description: 'All notes in the discussion.'
      field :reply_id, DiscussionID, null: false,
        description: 'ID used to reply to this discussion.'

      # DiscussionID.coerce_result is suitable here, but will always mark this
      # as being a 'Discussion'. Using `GlobalId.build` guarantees that we get
      # the correct class, and that it matches `id`.
      def reply_id
        ::Gitlab::GlobalId.build(object, id: object.reply_id)
      end

      def noteable
        noteable = object.noteable

        return unless Ability.allowed?(context[:current_user], :"read_#{noteable.to_ability_name}", noteable)

        noteable
      end
    end
  end
end
