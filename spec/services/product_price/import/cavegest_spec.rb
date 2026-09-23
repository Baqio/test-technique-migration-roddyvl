require "spec_helper"

RSpec.describe ProductPrice::Import::Cavegest do
  let(:importer) { described_class.new(data_path("export_tarifs_cavegest.csv")) }

  before { importer.call }

  it "keeps two decimals when the source uses a French comma" do
    price = ProductPrice.joins(:product)
                         .find_by(products: { reference: "LANM3" }, grid_code: "DEPC")

    expect(price.amount_ht).to eq(13.32)
  end

  it "keeps the decimal part of the container volume" do
    product = Product.find_by(reference: "CUV234")

    expect(product.volume_ml).to eq(375)
  end

  it "rejects a product reference that appears twice with conflicting data" do
    expect(importer.report.errors.map(&:locator)).to include("VIENM6")
  end

  it "does not create a price for an empty grid cell" do
    product = Product.find_by(reference: "LANM3")

    expect(ProductPrice.exists?(product: product, grid_code: "SALON")).to be false
  end

  it "skips section header rows instead of creating a fake product" do
    expect(Product.where(reference: "--- AOP ROUGES ---")).to be_empty
  end

  it "converts the EXPO price from TTC to HT using the row's own TVA rate" do
    price = ProductPrice.joins(:product)
                        .find_by(products: { reference: "TRA231" }, grid_code: "EXPO")

    expect(price.amount_ht).to eq(11.66)
  end
end
