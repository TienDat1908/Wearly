class RemovePrimaryPhotoAttachmentForeignKeyFromProducts < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :products,
      :active_storage_attachments,
      column: :primary_photo_attachment_id,
      if_exists: true
  end
end
