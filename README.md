# Slither
by Ryan Wood http://ryanwood.com

# Description:

A simple, clean DSL for describing, writing, and parsing fixed-width text files.

## Features:

* Easy DSL syntax
* Can parse and format fixed width files
* Templated sections for reuse
* Helpful error messages for invalid data

## Synopsis:

Create a Slither::Defintion to describe a file format
```ruby
  Slither.define :simple, :by_bytes => false do |d|

    # This is a template section that can be reused in other sections
    d.template :boundary do |t|
      t.column :record_type, 4
      t.column :company_id, 12
    end

    # Create a header section
    #   alternatively, you can define the section on the fly by using metaprogramming
    #   ex: d.header(:align => :left) { |header| ... }
    d.section(:header, :align => :left) do |header|
      # The trap tells Slither which lines should fall into this section
      header.trap { |line| line[0,4] == 'HEAD' }
      # Use the boundary template for the columns
      header.template :boundary
    end

    d.section(:body) do |body|
      body.trap { |line| line[0,4] =~ /[^(HEAD|FOOT)]/ }
      body.column :id, 10, :type => :integer
      body.column :name, 10, :align => :left
      body.spacer 3
      body.column :state, 2
    end

    d.section(:footer) do |footer|
      footer.trap { |line| line[0,4] == 'FOOT' }
      footer.template :boundary
      footer.column :record_count, 10
    end
  end
```

Supported types are: `string, integer, date, float, money, and money_with_implied_decimal`.

Use `:by_bytes => true` (default) to allow newlines within rows and specify length in bytes.
Use `:by_bytes => false` to support sections of different lengths and length specification
in number of characters.

Then either feed it a nested struct with data values to create the file in the defined format:

```ruby
  test_data = {
    :body => [
      { :id => 12, :name => "Ryan", :state => 'SC' },
      { :id => 23, :name => "Joe", :state => 'VA' },
      { :id => 42, :name => "Tommy", :state => 'FL' },
    ],
    :header => { :record_type => 'HEAD', :company_id => 'ABC'  },
    :footer => { :record_type => 'FOOT', :company_id => 'ABC'  }
  }

  # Generates the file as a string
  puts Slither.generate(:simple, test_data)
  # =>
  #   HEAD         ABC
  #         12Ryan         SC
  #         23Joe          VA
  #         42Tommy        FL
  # FOOT         ABC

  # Writes the file
  Slither.write(output_filename, :simple, test_data)
```

or parse files already in that format into a nested hash:
```ruby
   parsed_data = Slither.parse(input_filename, :simple)
   parsed_data = Slither.parseIo(io_object, :simple)
```

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Slither project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ryanwood/slither/blob/master/CODE_OF_CONDUCT.md).
