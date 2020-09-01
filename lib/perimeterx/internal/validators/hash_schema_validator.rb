def validate_hash_schema(hash, schema)
  hash.each do |key, value|
    if schema.key?(key) && value != nil
      # validate value types in hash are according to schema
      if !schema[key][:types].include?(value.class)
        raise PxConfigurationException.new("PerimeterX: Type of #{key} should be one of #{schema[key][:types]} but instead is #{value.class}")
      end
      
      # validate arrays elments types are according to schema
      if value.class == Array
        value.each do |element|
          if !schema[key][:allowed_element_types].include?(element.class)
            raise PxConfigurationException.new("PerimeterX: #{key} may only contain elements of the following types: #{schema[key][:allowed_element_types]} but includes element of type #{element.class}")
          end
        end
      end
    end
  end

  # validate required fields exist in hash
  schema.each do |key, value|
    if value[:required] && hash[key].nil?
      raise PxConfigurationException.new("PerimeterX: #{key} configuration is missing")
    end
  end
end
