require "fileutils"

module DataMapperSalesforce
  class SoapWrapper
    class ClassesFailedToGenerate < StandardError; end

    def initialize(module_name, driver_name, wsdl_path, api_dir)
      @module_name, @driver_name, @wsdl_path, @api_dir = module_name, driver_name, File.expand_path(wsdl_path), File.expand_path(api_dir)
      generate_soap_classes
      driver
    end
    attr_reader :module_name, :driver_name, :wsdl_path, :api_dir

    def driver
      @driver ||= Object.const_get(module_name).const_get(driver_name).new
    end

    def generate_soap_classes
      unless File.file?(wsdl_path)
        raise Errno::ENOENT, "Could not find the WSDL at #{wsdl_path}"
      end

      unless File.directory?(wsdl_api_dir)
        FileUtils.mkdir_p wsdl_api_dir
      end

      unless files_exist?
        Dir.chdir(wsdl_api_dir) do
          unless system("wsdl2ruby.rb", "--wsdl", wsdl_path, "--module_path", module_name, "--classdef", module_name, "--type", "client")
            raise ClassesFailedToGenerate, "Could not generate the ruby classes from the WSDL"
          end
          FileUtils.rm Dir["*Client.rb"]
        end
      end

      $:.push wsdl_api_dir
      require "#{module_name}Driver"
    end

    def files_exist?
      %w( .rb Driver.rb MappingRegistry.rb ).all? do |suffix|
        File.exist?("#{wsdl_api_dir}/#{module_name}#{suffix}")
      end
    end

    def wsdl_api_dir
      "#{api_dir}/#{File.basename(wsdl_path)}"
    end
  end
end