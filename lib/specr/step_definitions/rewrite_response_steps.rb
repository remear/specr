# frozen_string_literal: true
And(/^I set the response attribute "(.*?)" to "(.*?)"(?: for step "(.*?)")?$/) do |*args|
  attribute = args[0]
  value = args[1]
  step = args[2]

  response = Specr.client.last_body
  new_response = deep_set(response, value, *attribute.split('.'))
  Specr.client.extracer.rewrite_response_for_step(new_response, step)
end

def deep_set(hash, value, *keys)
  new_hash = {}
  keys[0...-1].inject(new_hash) do |h, key|
    h[key] = {}
  end[keys.last] = value

  deep_merge(hash, new_hash)
end

def deep_merge(hash1, hash2)
  hash2.each_pair do |k,v|
    tv = hash1[k]
    if tv.is_a?(Hash) && v.is_a?(Hash)
      hash1[k] = deep_merge(tv, v)
    else
      hash1[k] = v
    end
  end
  hash1
end
