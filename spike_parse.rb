require 'csv'

def print_company_header company_info
  puts company_info['Company Name']
  puts company_info['Company Type']
end

csv_filename = 'startups_input.csv'

search_criteria = { 'Primary Contact Email' => '',
                    'Primary Contact First Name' => '' }

options = { :headers => :first_row,
            :converters => [:numeric] }

matches = nil
headers = nil

CSV.open( csv_filename, "r:ISO-8859-1", options ) do |csv|
  matches = csv.find_all do |row|
    puts "Alright we've got #{row['Company Name']}"
    if(row['Meta Email'])
      puts "For primary contact email is it:"
      row['Meta Email'].split(";").each_with_index do |potential_email, i|
        puts "#{i}) #{potential_email}"
      end
      choice = gets
    end
  end
end
