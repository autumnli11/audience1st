Given /a seatmap "(.*)" with seats (.*)/ do |name,seats|
  create(:seatmap, :name => name, :seat_rows => [seats.split(/\s*,\s*/)])
end

Given /the seatmap "(.*)" exists/ do |name|
  create(:seatmap, :name => name)
end

Then /a seatmap named "(.*)" should (not )?exist/ do |name,no|
  if no
    expect(Seatmap.find_by(:name => name)).to be_nil
  else
    expect(Seatmap.find_by(:name => name)).to be_a_kind_of Seatmap
  end
end

When /I (press|follow) "(.*)" for the "(.*)" seatmap/ do |action,control,name|
  @seatmap = Seatmap.find_by!(:name => name)
  within("#sm-#{@seatmap.id}") do
    steps %Q{When I #{action} "#{control}"}
  end
end

When /I fill in the "(.*)" seatmap image URL as "(.*)" and name as "(.*)"/ do |sm,url,name|
  within("#sm-#{Seatmap.find_by!(:name => sm).id}") do
    fill_in "seatmap[image_url]", :with => url
    fill_in "seatmap[name]", :with => name
  end
end

When /I fill in "(.*)" and "(.*)" as the name and image for a new seatmap/ do |name,image_url|
  within '#new_seatmap_form' do
    fill_in :name, :with => name
    fill_in :image_url, :with => image_url
  end
end

When /I upload the seatmap "(.*\.csv)"/ do |file|
  within '#new_seatmap_form' do
    attach_file 'csv', "#{Rails.root}/spec/import_test_files/seatmaps/#{file}", :visible => false
    click_button 'Upload'
  end
end

When /I try to change the seatmap for that performance to "(.*)"/ do |seatmap_name|
  visit edit_show_showdate_path(@showdate.show,@showdate)
  select seatmap_name, :from => 'Seat map'
  click_button 'Save Changes'
end

# After making changes - need to reload the AR objects that have been instance variables throughout
# the scenario
Then /the "(.*)" performance should use the "(.*)" seatmap/ do |thedate,name|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  steps %Q{Then that performance should use the "#{name}" seatmap}
end

Then /that performance should use the "(.*)" seatmap/ do |name|
  expect(@showdate.reload.seatmap.name).to eq(name)
end

Then /the "(.*)" performance should be General Admission/ do |thedate|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  expect(@showdate.seatmap).to be_blank
end

Then /that performance should be General Admission/ do
  expect(@showdate.reload.seatmap).to be_blank
end

Then /that seatmap should have image URL "(.*)" and name "(.*)"/ do |url,name|
  @seatmap.reload
  expect(@seatmap.name).to eq(name)
  expect(@seatmap.image_url).to eq(url)
end
