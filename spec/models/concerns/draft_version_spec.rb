require 'spec_helper'

class TestObject < ActiveFedora::Base
  include DraftVersion
end


describe DraftVersion do

  describe '.build_draft_version' do
    subject { TestObject.build_draft_version(attrs) }

    context 'with no PID given' do
      let(:attrs) { Hash.new }

      it 'sets the draft namespace so that the saved object will have a draft PID' do
        expect(subject.inner_object.namespace).to eq 'draft'
        expect(subject.pid).to be_nil
        subject.save!
        expect(subject.pid).to match /^draft:.*$/
      end
    end

    context 'with a namespace given' do
      let(:attrs) {{ namespace: 'tufts' }}

      it 'overrides the namespace with the draft namespace' do
        expect(subject.inner_object.namespace).to eq 'draft'
      end
    end

    context 'with a non-draft PID given' do
      let(:pid) { 'tufts:123' }
      let(:draft_pid) { 'draft:123' }
      let(:attrs) {{ pid: pid }}

      it 'converts the PID to a draft PID' do
        expect(subject.pid).to eq draft_pid
      end
    end
  end

  describe '#publish!' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      @obj = TuftsImage.create(title: 'My title', displays: ['dl'])
    end

    after do
      @obj.delete if @obj
    end

    context "when a published version does not exist" do
      it "results in a published copy of the draft existing" do
        published_pid = PidUtils.to_published(@obj.pid)
        expect(TuftsImage.exists?(published_pid)).to be_falsey

        @obj.publish!

        expect(TuftsImage.exists?(published_pid)).to be_truthy
      end
    end

    context "when a published version already exists" do
      it "destroys the existing published copy" do
        published_pid = PidUtils.to_published(@obj.pid)

        @obj.publish!

        published_obj = double('published')
        expect(published_obj).to receive(:destroy) { true }
        expect(TuftsImage).to receive(:find).with(published_pid).once { published_obj }

        @obj.publish!
      end

      it "results in a published copy of the original" do
        @obj.publish!

        published_obj = @obj.find_published

        expect(published_obj).to be_published
        expect(published_obj.title).to eq('My title')
        expect(published_obj.displays).to eq(['dl'])
      end
    end


    it 'adds an entry to the audit log' do
      expect(@obj).to receive(:audit).with(instance_of(User), 'Pushed to production').once

      # This needs to be happen a number of times because of the multiple object updates in #publish!
      expect(@obj).to receive(:audit).with(instance_of(User), 'Metadata updated DCA-ADMIN').once

      @obj.publish!(user.id)
    end

    it 'results in the image being published' do
      skip "this test randomly fails"

      expect(@obj.published_at).to eq(nil)

      @obj.publish!
      @obj.reload
      expect(@obj.published?).to be_truthy
    end

    it 'only updates the published_at time when actually published' do
      expect(@obj.published_at).to eq nil

      @obj.publish!(user.id)

      expect(@obj.published_at).to_not be_nil
    end
  end

  describe '#find_draft' do
    before { ActiveFedora::Base.delete_all }

    let!(:record) { TestObject.create!(pid: 'tufts:123') }

    context 'given a record with a draft version' do
      let!(:draft_record) {
        obj = TestObject.build_draft_version(record.attributes.except('id').merge(pid: record.pid))
        obj.save!
        obj
      }

      it 'finds the draft version of that record' do
        expect(record.find_draft).to eq draft_record
      end
    end

    context 'given a record without a draft version' do
      it 'raises an exception' do
        expect{ record.find_draft }.to raise_error ActiveFedora::ObjectNotFoundError
      end
    end
  end


  describe '#draft?' do
    subject { TestObject.new(pid: pid, namespace: namespace) }

    context 'with a non-draft PID' do
      let(:pid) { 'tufts:123' }
      let(:namespace) { nil }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end

    context 'a PID with the draft namespace' do
      let(:pid) { 'draft:123' }
      let(:namespace) { nil }

      it 'reports draft status' do
        expect(subject.draft?).to be_truthy
      end
    end

    context 'with no PID, but draft namespace' do
      let(:pid) { nil }
      let(:namespace) { PidUtils.draft_namespace }

      it 'reports draft status' do
        expect(subject.draft?).to be_truthy
      end
    end

    context 'with no PID, but non-draft namespace' do
      let(:pid) { nil }
      let(:namespace) { PidUtils.published_namespace }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end

    context 'with no PID and no namespace' do
      let(:pid) { nil }
      let(:namespace) { nil }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end
  end

end