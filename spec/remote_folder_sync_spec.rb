require 'spec_helper'
require 'remote_folder_sync'

describe RemoteFolderSync do
  it "should have a VERSION constant" do
    subject.const_get('VERSION').should_not be_empty
  end
end
