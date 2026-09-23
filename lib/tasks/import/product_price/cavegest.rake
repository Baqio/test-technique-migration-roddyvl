namespace :import do
  namespace :product_price do
    desc "Importe les produits et grilles tarifaires CaveGest"
    task :cavegest do
      importer = ProductPrice::Import::Cavegest.new(File.join(DATA_DIR, "export_tarifs_cavegest.csv"))
      importer.call
      puts importer.report
    end
  end
end
