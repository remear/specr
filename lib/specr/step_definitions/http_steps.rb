# frozen_string_literal: true
When /^I set headers:$/ do |request_headers|
  Specr.client.headers = Specr.configuration.default_headers.merge(request_headers.rows_hash)
end

When(/^I (\w+) to ((?:https?:\/)?\/\S*)$/) do |verb, url|
  Specr.client.send(verb.downcase, url)
end

When(/^I (\w+) to ((?:https?:\/)?\/\S*) with the body:$/) do |verb, url, body|
  Specr.client.send(verb.downcase.to_sym, url, body)
end

When(/^I (POST|PATCH) to (\/\S*?) with the file "(.*?)" as "(.*?)"$/) do |verb, url, file, file_field|
  Specr.client.send("#{verb.downcase}_multipart", url, Specr.client.hydrater(file), file_field, nil)
end

When(/^I (POST|PATCH) to (\/\S*?) with the "(.*?)" file as "(.*?)" and the body:$/) do |verb, url, file, file_field, body|
  Specr.client.send("#{verb.downcase}_multipart", url, Specr.client.hydrater(file), file_field, body)
end

When(/^I (\w+) to the "(.*?)" link with the body:$/) do |verb, keys, body|
  step "I #{verb} to #{Specr.client.get_link(keys)} with the body:", body
end

When(/^I (\w+) to the "(.*?)" link$/) do |verb, keys|
  step "I #{verb} to #{Specr.client.get_link(keys)}"
end

Then(/^the response has this schema:$/) do |schema|
  Specr.client.validate(schema)
end

Then(/^the response is valid according to the "(.*?)" schema$/) do |filename|
  Specr.client.validate(filename)
end

Then(/^I should get a (.+) status code$/) do |code|
  message = Specr.client.last_body.fetch('description', '') if Specr.client.last_body
  assert_equal code.to_i, Specr.client.last_code, message
end

Then(/^there should be no response body$/) do
  assert_nil Specr.client.last_body
end
