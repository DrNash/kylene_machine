require 'csv'
require 'colorize'

class Employee
  attr_accessor :first_name, :last_name, :position
end

def print_company_header company_info
  puts "\n#{company_info['Company Name']} - #{company_info['Company Type']}".blue
  if(company_info['Meta Name'] || company_info['Meta Email'])
    puts sprintf("%60s%60s%60s", "Overloaded Emails", "Overloaded Names/Positions", "Overloaded Addresses").green
    email_array = field_to_array(company_info['Meta Email'])
    contact_array = field_to_array(company_info['Meta Name'])
    address = company_info['Full Address']
    6.times do |time|
      puts sprintf("%60s%60s%60s",
                   (email_array[time].strip if email_array[time]),
                   (contact_array[time].strip if contact_array[time]),
                   address)

    end
  end
end

def field_to_array field
  arr = []
  if(field)
    arr = field.split(";")
  end
  arr
end

def get_primary_email emails_string
  puts "Choose the primary email:".light_blue
  emails_arr = emails_string.split(";")
  emails_arr.each_with_index do |potential_email, i|
    puts "#{i+1}) #{potential_email.strip}"
  end
  choice = gets.chomp.to_i
  parse_email_from_string(emails_arr[choice-1].strip)
end

def parse_email_from_string email_string
  result_email = email_string
  if(email_string.split(" - ")[1] != nil)
    result_email = email_string.split(" - ")[1].strip
  else
    puts "Email entry malformed, it is: #{email_string}".red
    puts "Writing #{email_string} to the record, note the company and check output later".red
  end
  result_email
end

def parse_contact_from_string name_string
  emp = Employee.new
  if(name_string.split(" -")[0] != nil)
    result = name_string.split(" -")
    name = result[0].strip
    emp.position = result[1].strip if result[1] != nil
    interim_result = name.split(" ")
    emp.first_name = interim_result.shift
    emp.last_name = interim_result.join(" ")
  else
    puts "Name entry malformed, it is: #{name_string}".red
    puts "Writing #{name_string} to the record, note the company and check output later".red
  end
  emp
end

def get_primary_contact names_string
  puts "Choose the primary Contact:".light_blue
  names_arr = names_string.split(";")
  names_arr.each_with_index do |potential_name, i|
    puts "#{i+1}) #{potential_name.strip}"
  end
  choice = gets.chomp.to_i
  parse_contact_from_string(names_arr[choice-1].strip)
end

def write_headers
  if(File::size?(@output_csv_filename) == nil)
    File.open(@output_csv_filename, "w") do |f|
      f << "Company Name,Company Web Site,Company Type,Company Summary (140 chars),Company Logo URL,Company Full Address,Company Street 1,Company Street 2,Company City,Company State,Company ZIP,Company LinkedIn,Company Facebook,Company Twitter,Primary Contact Email,Meta Email,Primary Contact First Name,Meta Name,Primary Contact Last Name,Primary Contact Position,Primary Contact Home Phone,Primary Contact Work Phone,Primary Contact Mobile Phone,Primary Contact LinkedIn URL,Primary Contact Twitter URL,Primary Contact Facebook URL,Primary Contact Blog URL,Primary Contact Bio (140 char),Team Member 1 First Name,Team Member 1 Last Name,Team Member 1 Position,Team Member 1 Bio (Max 140 char),Team Member 2 First Name,Team Member 2 Last Name,Team Member 2 Position,Team Member 2 Bio (Max 140 char),Team Member 3 First Name,Team Member 3 Last Name,Team Member 3 Position,Team Member 3 Bio (Max 140 char),Team Member 4 First Name,Team Member 4 Last Name,Team Member 4 Position,Team Member 4 Bio (Max 140 char),Team Member 4 Bio (Max 140 char), Education, Accelerator, Incubator, Workspace, Accounting Firm, Consultant, Angel Group, Venue, Business Plan Competition, Economic Develp Agency, Entrepreneual Confrence, Financial Institution, Law Firm, Non-Profit, Other, Service Provider, University/College, Venture Fund\n"
    end
  end
end

def write_row file, row
  CSV.open( file, "a", @options) do |outfile_csv|
    outfile_csv << row
  end
end

def splice_files
  found = false
  CSV.open( @csv_filename, "r:ISO-8859-1", @options ) do |csv|
    CSV.open( @output_csv_filename, "r:ISO-8859-1", {:converters => [:numeric]} ) do |output_csv|
      last_company = output_csv.to_a.last[0]
      csv.find_all do |row|
        if(found)
          write_row(@output_csv_filename, row)
        elsif(row['Company Name'] == last_company)
          found = true
        end
      end
    end
  end
end

@options = { :headers => :first_row,
            :converters => [:numeric] }

puts "Input file:"
@csv_filename = gets.chomp
puts "Output file:"
@output_csv_filename = gets.chomp

write_headers

CSV.open( @csv_filename, "r:ISO-8859-1", @options ) do |csv|
  CSV.open( @output_csv_filename, "r:ISO-8859-1", {:converters => [:numeric]} ) do |output_csv|
    begin
      matches = csv.find_all do |row|
        print_company_header row
        if(row['Meta Email'])
          primary_email = get_primary_email(row['Meta Email'])
          puts "Email selected: #{primary_email}"
          row['Primary Contact Email'] = primary_email
          row['Meta Email'] = nil
        end

        if(row['Meta Name'])
          primary_contact = get_primary_contact(row['Meta Name'])
          row['Primary Contact First Name'] = primary_contact.first_name
          row['Primary Contact Last Name'] = primary_contact.last_name
          row['Primary Contact Position'] = primary_contact.position
          row['Meta Name'] = nil
        end

        output_row = output_csv.find { |r| r.index(row['Company Name']) }
        if(output_row)
          output_csv_row = CSV::Row.new(csv.headers, output_row)
        end

        unless(output_csv_row == row)
          puts "Row for #{row['Company Name']} valid, writing to output".green
          write_row(@output_csv_filename, row)
        end
      end
    rescue SystemExit, Interrupt
      splice_files
      exit 1
    end
  end
end
