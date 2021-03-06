require "spec_helper"

RSpec.describe GfrImageTransformer::SharpTransformer do
  let(:image_url) { "https://s3.amazonaws.com/media.listamax.com/listings/2020/02/25/apartment-for-sale-in-chalets-de-la-playa-in-vega-baja-puerto-rico-dc355701a612a0443b574c340996f35a.jpg" }
  let(:encoded_url) { "#{ENV.fetch("IMAGE_TRANSFORMER_DOMAIN")}/eyJidWNrZXQiOiJtZWRpYS5saXN0YW1heC5jb20iLCJrZXkiOiJsaXN0aW5ncy8yMDIwLzAyLzI1L2FwYXJ0bWVudC1mb3Itc2FsZS1pbi1jaGFsZXRzLWRlLWxhLXBsYXlhLWluLXZlZ2EtYmFqYS1wdWVydG8tcmljby1kYzM1NTcwMWE2MTJhMDQ0M2I1NzRjMzQwOTk2ZjM1YS5qcGciLCJlZGl0cyI6eyJyZXNpemUiOnsid2lkdGgiOjY0MCwiaGVpZ2h0Ijo0ODAsImZpdCI6ImNvdmVyIn19fQ==" }
  let(:metadata) { GfrImageTransformer::Metadata.new(image_url) }

  subject { described_class.new(metadata) }

  it "should build a variant image" do
    variant = subject.resize(640, 480).generate

    expect(variant.url).to eq(encoded_url)
    expect(variant.width).to eq(640)
    expect(variant.height).to eq(480)
  end

  describe "with background" do
    let(:image_url) { "listings/logos/clasificados-pr-logo.png" }
    let(:encoded_url) { "#{ENV.fetch("IMAGE_TRANSFORMER_DOMAIN")}/eyJidWNrZXQiOiJtZWRpYS5saXN0YW1heC5jb20iLCJrZXkiOiJsaXN0aW5ncy9sb2dvcy9jbGFzaWZpY2Fkb3MtcHItbG9nby5wbmciLCJlZGl0cyI6eyJyZXNpemUiOnsid2lkdGgiOjE4NSwiaGVpZ2h0IjoxMTUsImZpdCI6ImNvdmVyIiwiYmFja2dyb3VuZCI6eyJyIjoyNTUsImciOjI1NSwiYiI6MjU1LCJhbHBoYSI6MX19LCJmbGF0dGVuIjp7ImJhY2tncm91bmQiOnsiciI6MjU1LCJnIjoyNTUsImIiOjI1NSwiYWxwaGEiOjF9fSwianBlZyI6eyJxdWFsaXR5Ijo5MH0sInRvRm9ybWF0IjoianBlZyJ9fQ==" }

    it "sets a white background for the image" do
      variant = subject.resize(185, 115, resizer_mode: :cover, fill_color: :white).with_background(:white).jpeg.generate

      expect(variant.url).to eq(encoded_url)
      expect(variant.width).to eq(185)
      expect(variant.height).to eq(115)
    end
  end

  it "should throw error when invalid resizer mode is passed" do
    expect {
      subject.resize(640, 480, resizer_mode: :invalid).generate
    }.to raise_error(ArgumentError)
  end

  it "should calculate the height when no resize height is passed" do
    VCR.use_cassette("fetching_image_height_from_original_url") do
      image = subject.resize(640, 0).generate

      expect(image.height).to eq(359)
    end
  end

  it "should calculate the width when no resize width is passed" do
    VCR.use_cassette("fetching_image_width_from_original_url") do
      image = subject.resize(0, 480).generate

      expect(image.width).to eq(854)
    end
  end

  it "should output to jpeg" do
    image = subject.jpeg(quality: 90).generate

    expect(image.url).to eq("#{ENV.fetch("IMAGE_TRANSFORMER_DOMAIN")}/eyJidWNrZXQiOiJtZWRpYS5saXN0YW1heC5jb20iLCJrZXkiOiJsaXN0aW5ncy8yMDIwLzAyLzI1L2FwYXJ0bWVudC1mb3Itc2FsZS1pbi1jaGFsZXRzLWRlLWxhLXBsYXlhLWluLXZlZ2EtYmFqYS1wdWVydG8tcmljby1kYzM1NTcwMWE2MTJhMDQ0M2I1NzRjMzQwOTk2ZjM1YS5qcGciLCJlZGl0cyI6eyJqcGVnIjp7InF1YWxpdHkiOjkwfSwidG9Gb3JtYXQiOiJqcGVnIn19")
  end

  describe "#key" do
    it "should extract key when the bucket is a sub-domain of the url" do
      image_url = "https://media.listamax.com.s3.amazonaws.com/listings/2020/02/19/shopper.png"

      transformer = described_class.new(GfrImageTransformer::Metadata.new(image_url))

      expect(transformer.key).to eq("listings/2020/02/19/shopper.png")
    end

    it "should extract key when the bucket name is part of the url" do
      image_url = "https://s3.amazonaws.com/media.listamax.com/listings/2020/02/19/shopper.png"

      transformer = described_class.new(GfrImageTransformer::Metadata.new(image_url))

      expect(transformer.key).to eq("listings/2020/02/19/shopper.png")
    end
  end
end
