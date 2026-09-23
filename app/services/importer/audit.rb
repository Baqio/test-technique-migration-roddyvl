class Importer::Audit
  def self.call = new.call

  def call
    report = MigrationReport.new

    check_duplicate_references(report)
    check_products_without_price(report)
    add_counts(report)

    report.to_s
  end

  def to_s
    call.to_s
  end

  private

  def check_duplicate_references(report)
    Customer.group(:reference).having("count(*) > 1").count.each_key do |reference|
      report.error(source: "customers", locator: reference, message: "Référence client en double en base")
    end

    Product.group(:reference).having("count(*) > 1").count.each_key do |reference|
      report.error(source: "products", locator: reference, message: "Référence produit en double en base")
    end
  end

  def check_products_without_price(report)
    Product.left_joins(:product_prices).where(product_prices: { id: nil }).find_each do |product|
      report.warn(source: "products", locator: product.reference, message: "Aucun tarif enregistré pour ce produit")
    end
  end

  def add_counts(report)
    report.count("customers_total", Customer.count)
    report.count("customers_active", Customer.where(active: true).count)
    report.count("products_total", Product.count)
    report.count("product_prices_total", ProductPrice.count)
  end
end
