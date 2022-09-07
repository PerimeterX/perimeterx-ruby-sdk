# frozen_string_literal: true

def validate_hash_schema(hash, schema)
  hash.each do |key, value|
    next unless schema.key?(key) && !value.nil?

    # validate value types in hash are according to schema
    unless schema[key][:types].include?(value.class)
      raise PxConfigurationException,
            "PerimeterX: Type of #{key} should be one of #{schema[key][:types]} but instead is #{value.class}"
    end

    # validate arrays elments types are according to schema
    next unless value.instance_of?(Array)

    value.each do |element|
      unless schema[key][:allowed_element_types].include?(element.class)
        raise PxConfigurationException,
              "PerimeterX: #{key} may only contain elements of the following types: #{schema[key][:allowed_element_types]} but includes element of type #{element.class}"
      end
    end
  end

  # validate required fields exist in hash
  schema.each do |key, value|
    raise PxConfigurationException, "PerimeterX: #{key} configuration is missing" if value[:required] && hash[key].nil?
  end
end
