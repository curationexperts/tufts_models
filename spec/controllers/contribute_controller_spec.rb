require 'spec_helper'

describe ContributeController do
  before do
    @user = FactoryGirl.create(:admin)
    sign_in @user
  end

  describe "GET 'home'" do
    it "returns http success" do
      get 'home'
      response.should be_success
    end
  end

  describe "GET 'license'" do
    it "returns http success" do
      get 'license'
      response.should be_success
    end
  end

  describe "GET 'new'" do

    it "redirects to contribute home when no deposit type is specified" do
      get 'new'
      response.should redirect_to contribute_path
    end

    describe 'with valid deposit_type' do
      before :all do
        # TODO: use factory here
        @deposit_type = DepositType.create(:display_name => 'Test Option', :deposit_view => 'generic_deposit', :deposit_agreement => 'Legal links here...')
        @contribution = TuftsPdf.new
      end

      after :all do
        @deposit_type.destroy
      end
      render_views

      it 'should render the correct template' do
        get 'new', {deposit_type: @deposit_type.id}
        response.should render_template('contribute/deposit_view/_generic_deposit')
      end

      it 'should include a title input'
      it 'should include a file upload input'

      it 'should include deposit license text' do
        get 'new', {deposit_type: @deposit_type.id}
        response.body.should have_content @deposit_type.deposit_agreement
      end
    end
  end

  describe "GET 'redirect'" do
    it "redirects to contribute when no deposit type is specified" do
      get 'redirect'
      response.should redirect_to contribute_path
    end
  end

end
