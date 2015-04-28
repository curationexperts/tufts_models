require 'spec_helper'

describe LocalPathService do
  context "for an image" do
    let(:image) { TuftsImage.new(attributes) }
    let(:attributes) { { pid: pid } }

    let(:path_service) { LocalPathService.new(image, 'Archival.tif', 'tif') }


    describe "#remote_url" do
      subject { path_service.remote_url }
      context "when pid is provided by the user" do
        let(:pid) { 'tufts:MS054.003.DO.02108' }

        it "should give a remote url" do
          expect(subject).to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/archival_tif/MS054.003.DO.02108.archival.tif'
        end
      end

      context "when pid is autogenerated" do
        let(:pid) { 'tufts:1234' }
        it "should give a remote url" do
          expect(subject).to eq 'http://bucket01.lib.tufts.edu/data01/tufts/sas/archival_tif/1234.archival.tif'
        end
      end
    end

    describe "#local_path" do
      subject { path_service.local_path }
      context "when pid is provided by the user" do
        let(:pid) { 'tufts:MS054.003.DO.02108' }

        it "should give a local_path" do
          expect(subject).to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/archival_tif/MS054.003.DO.02108.archival.tif", __FILE__)
        end
      end
      context "when pid is autogenerated" do
        let(:pid) { 'tufts:1234' }
        it "should give a local_path" do
          expect(subject).to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/sas/archival_tif/1234.archival.tif", __FILE__)
        end
      end
    end
  end

  context "for a pdf" do
    let(:pdf) { TuftsImage.new(attributes) }
    let(:attributes) { { pid: pid } }

    let(:path_service) { LocalPathService.new(pdf, 'Archival.pdf', 'pdf') }

    let(:pid) { 'tufts:MS054.003.DO.02108' }
    describe "#remote_url" do
      subject { path_service.remote_url }

      context "with a collection" do
        let(:collection_id) { 'tufts:UA069.001.DO.UA015' }
        before do
          unless ActiveFedora::Base.exists? collection_id
            ActiveFedora::FixtureLoader.new('spec/fixtures').import_and_index(collection_id)
          end
          pdf.collection_id = collection_id
        end

        it "should give a remote URL" do
          expect(pdf.collection_id).to eq collection_id
          expect(subject).to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/UA015/archival_pdf/MS054.003.DO.02108.archival.pdf'
        end

      end
      it "should give a remote url" do
        expect(subject).to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/archival_pdf/MS054.003.DO.02108.archival.pdf'
      end
    end

    describe "#local_path" do
      subject { path_service.local_path }
      it "should give a local_path" do
        expect(subject).to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/archival_pdf/MS054.003.DO.02108.archival.pdf", __FILE__)
      end
    end
  end

  context "a generic object" do
    let(:generic_object) { TuftsGenericObject.new(attributes) }
    let(:pid) { 'tufts:MS054.003.DO.02108' }
    let(:attributes) { { pid: pid } }
    let(:path_service) { LocalPathService.new(generic_object, 'GENERIC-CONTENT', 'zip') }

    describe "#remote_url" do
      subject { path_service.remote_url }
      it { is_expected.to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/generic/MS054.003.DO.02108.zip' }
    end

    describe "#local_path" do
      subject { path_service.local_path }
      it { is_expected.to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/generic/MS054.003.DO.02108.zip", __FILE__) }
    end
  end

  context "an audio" do
    let(:audio) { TuftsAudio.new(attributes) }
    let(:pid) { 'tufts:MS054.003.DO.02108' }
    let(:attributes) { { pid: pid } }
    let(:path_service) { LocalPathService.new(audio, 'ARCHIVAL_WAV', 'wav') }

    describe "#remote_url" do
      subject { path_service.remote_url }
      it { is_expected.to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav' }

      context "with legacy datastreams on different data shares" do
        before do
          audio.inner_object.datastreams['ARCHIVAL_WAV'].dsLocation = 'http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav'
        end
        it { is_expected.to eq 'http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav' }
      end

      context "with xml" do
        let(:path_service) { LocalPathService.new(audio, 'ARCHIVAL_XML', 'xml') }
        it { is_expected.to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/archival_xml/MS054.003.DO.02108.archival.xml' }
      end

      context "with mp3" do
        let(:path_service) { LocalPathService.new(audio, 'ACCESS_MP3', 'mp3') }
        it { is_expected.to eq 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS054/access_mp3/MS054.003.DO.02108.access.mp3' }
      end
    end

    describe "#local_path" do
      subject { path_service.local_path }
      it { is_expected.to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav", __FILE__) }

      context "with legacy datastreams on different data shares" do
        # if mira touches an object with data stored in a legacy location it shouldn't
        # start moving that data around to the new store or looking for it somewhere
        # it is not
        before do
          audio.inner_object.datastreams['ARCHIVAL_WAV'].dsLocation = 'http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav'
        end
        it { is_expected.to eq File.expand_path("../../fixtures/local_object_store/data05/tufts/central/dca/MS054/archival_wav/MS054.003.DO.02108.archival.wav", __FILE__) }
      end

      context "with xml" do
        let(:path_service) { LocalPathService.new(audio, 'ARCHIVAL_XML', 'xml') }
        it { is_expected.to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/archival_xml/MS054.003.DO.02108.archival.xml", __FILE__) }
      end

      context "with mp3" do
        let(:path_service) { LocalPathService.new(audio, 'ACCESS_MP3', 'mp3') }
        it { is_expected.to eq File.expand_path("../../fixtures/local_object_store/data01/tufts/central/dca/MS054/access_mp3/MS054.003.DO.02108.access.mp3", __FILE__) }
      end
    end
  end
end