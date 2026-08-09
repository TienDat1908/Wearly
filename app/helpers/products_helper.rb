module ProductsHelper
  def product_type_label(type)
    key = type.to_s
    I18n.t("products.types.#{key}", default: key.tr("_", " ").capitalize)
  end

  def product_status_label(status)
    key = status.to_s
    I18n.t("products.statuses.#{key}", default: key.tr("_", " ").capitalize)
  end

  def product_type_options(include_blank: false, blank_label: nil)
    options = Product.product_types.keys.map { |type| [product_type_label(type), type] }
    return options unless include_blank

    [[blank_label || t("products.all_types"), ""]] + options
  end

  def user_role_label(role)
    key = role.to_s
    I18n.t("users.roles.#{key}", default: key.tr("_", " ").capitalize)
  end

  def user_status_label(status)
    key = status.to_s
    I18n.t("users.statuses.#{key}", default: key.tr("_", " ").capitalize)
  end

  def weekday_labels_short
    I18n.t("date.abbr_day_names")
  end
end
