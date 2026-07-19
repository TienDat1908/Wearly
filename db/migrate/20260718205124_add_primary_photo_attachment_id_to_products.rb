class AddPrimaryPhotoAttachmentIdToProducts < ActiveRecord::Migration[7.2]
  def change
    add_reference :products,
      :primary_photo_attachment,
      foreign_key: { to_table: :active_storage_attachments },
      index: true
  end
end
