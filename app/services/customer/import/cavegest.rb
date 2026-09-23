class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS = { "C" => "customer", "F" => "supplier", "P" => "prospect", "R" => "customer" }.freeze

  def call
    imported = 0

    (2..sheet.last_row).each do |i|
      row = sheet.row(i)
      
      begin
          tier = N.text(row[19])

        if tier == "R"
          report.warn(
            source:,
            locator: N.text(row[0]),
            message: "Client de type Revendeur (R), mappé automatiquement sur 'customer', à confirmer avec le client"
          )
        end

        creation_date = begin
          N.date(row[25])
        rescue ArgumentError
          report.warn(source:, locator: N.text(row[0]), message: "Date de création illisible (#{row[25].inspect}), ignorée")
          nil
        end

        shipping_present = row[11..18].any? { |v| N.text(v).present? }
        reference = N.text(row[0])
        customer = Customer.find_or_initialize_by(reference:)
        customer.update!(
          reference:,
          company_name:      N.text(row[3]),
          first_name:        N.text(row[2]),
          last_name:         N.text(row[1]),
          address1:          N.text(row[4]),
          city:              N.text(row[6]),
          zip:               N.zip(row[5]),
          country_code:      N.country_code(row[7]),
          phone:             row[9].to_s,
          mobile:            row[10].to_s,
          email:             row[8].to_s,
          kind:              KINDS[tier],
          customer_category: N.text(row[20]),
          price_grid_code:   N.text(row[21]),
          vat_number:        N.text(row[23]),
          excise_number:     N.text(row[24]),
          creation_date:,
          active: row[26].to_i.zero?,
          use_billing_address:   !shipping_present,
          shipping_company_name: shipping_present ? N.text(row[13]) : nil,
          shipping_first_name:   shipping_present ? N.text(row[12]) : nil,
          shipping_last_name:    shipping_present ? N.text(row[11]) : nil,
          shipping_address1:     shipping_present ? N.text(row[14]) : nil,
          shipping_city:         shipping_present ? N.text(row[16]) : nil,
          shipping_zip:          shipping_present ? N.zip(row[15]) : nil,
          shipping_country_code: shipping_present ? N.country_code(row[17]) : nil,
          shipping_phone:        shipping_present ? row[18].to_s.presence : nil
        )

        imported += 1

      rescue ActiveRecord::RecordInvalid => e 
        report.error(source:, locator: N.text(row[0]), message: e.message)
      end
    end

    puts "#{imported} clients importés"
  end

  private

  def sheet
    @sheet ||= Roo::Excelx.new(path).sheet(0)
  end
end
