class ProductPrice::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  COLUMN_SEP = ";".freeze
  GRID_CODES = %w[DEPC CHR EXPO PART SALON].freeze
  
  def call
    imported = 0
    seen_references = Set.new

    CSV.parse(File.read(path, encoding: 'iso-8859-1:UTF-8').lines.drop(2).join, headers: true, col_sep: COLUMN_SEP).each do |row|
      reference = N.text(row["Ref"])
      next if reference.nil?
      next if N.text(row["Désignation"]).nil?
      
      begin
        if seen_references.include?(reference)
          report.error(
            source:,
            locator: reference,
            message: "Référence produit en double dans le fichier avec des données différentes, ligne ignorée"
          )
          next
        end
        seen_references << reference
        
        product = Product.find_or_initialize_by(reference:)
        product.update!(
          reference: reference,
          name:      N.text(row["Désignation"]),
          color:     N.text(row["Couleur"]),
          volume_ml: volume_ml(row["Contenant"]),
          vat_rate:  N.decimal(row["TVA"]),
          stock:     N.decimal(row["Stock"]).to_i
        )

        import_prices(product, row)
        imported += 1

      rescue ActiveRecord::RecordInvalid => e
        report.error(source:, locator: reference, message: e.message)
      end
    end

    puts "#{imported} produits importés"
    puts report.counters
  end

  private

  def import_prices(product, row)
    tva_rate = N.decimal(row["TVA"])

    GRID_CODES.each do |grid_code|
      if N.text(row[grid_code]).nil?
        report.count("#{grid_code.downcase}_prices_skipped")
        next
      end

      amount = N.decimal(row[grid_code])
      amount /= (1 + tva_rate / 100) if grid_code == "EXPO"

      product_price = ProductPrice.find_or_initialize_by(product:, grid_code:)
      product_price.update!(
        product:   product,
        grid_code: grid_code,
        amount_ht: amount.round(2)
      )
    end
  end

  def volume_ml(value)
    text = value.to_s
    return nil unless text.include?("-")

    size_part = text.split("-").last
    number = size_part[/\d+[.,]\d+|\d+/]
    return nil if number.nil?

  (number.tr(",", ".").to_f * 10).round
  end
end
