namespace :import do
  namespace :customer do
    desc "Importe les clients CaveGest"
    task :cavegest do
      importer = Customer::Import::Cavegest.new(File.join(DATA_DIR, "export_clients_cavegest.xlsx"))
      importer.call
      puts importer.report
    end
  end
end
