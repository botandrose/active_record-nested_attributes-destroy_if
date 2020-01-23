RSpec.describe ActiveRecord::NestedAttributesDestroyIf do
  before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :parents do |t|
          t.string :name
        end

        create_table :children do |t|
          t.references :parent
          t.string :name
        end
      end
    end

    class Parent < ActiveRecord::Base
      has_many :children
      accepts_nested_attributes_for :children, destroy_if: proc { |attrs| attrs["name"].blank? }
    end

    class Child < ActiveRecord::Base
      belongs_to :parent
    end
  end

  context "creating a new parent" do
    it "saves one new child" do
      subject = Parent.new({
        children_attributes: {
          "0" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "gubs@botandrose.com",
          },
        }
      })
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq ["gubs@botandrose.com"]
    end

    it "saves one new child and ignores a blank one" do
      subject = Parent.new({
        children_attributes: {
          "0" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "gubs@botandrose.com",
          },
          "1" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "",
          }
        }
      })
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq ["gubs@botandrose.com"]
    end

    it "ignores a blank child" do
      subject = Parent.new({
        children_attributes: {
          "0" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "",
          }
        }
      })
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq []
    end
  end

  context "saving an existing parent" do
    subject do
      s = Parent.new({
        children_attributes: {
          "0" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "micah@botandrose.com",
          },
        }
      })
      s.save(validate: false)
      s
    end

    it "saves one new child" do
      subject.attributes = {
        children_attributes: {
          "0" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "gubs@botandrose.com",
          },
        }
      }
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq ["micah@botandrose.com", "gubs@botandrose.com"]
    end

    it "saves one existing child, one new child, and ignores a blank one" do
      subject.attributes = {
        children_attributes: {
          "0" => {
            "id" => "1",
            "_destroy" => "false",
            "name" => "micah@botandrose.com",
          },
          "1" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "gubs@botandrose.com",
          },
          "2" => {
            "id" => "",
            "_destroy" => "false",
            "name" => "",
          }
        }
      }
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq ["micah@botandrose.com", "gubs@botandrose.com"]
    end

    it "removes an existing child" do
      subject.attributes = {
        children_attributes: {
          "0" => {
            "id" => "1",
            "_destroy" => "false",
            "name" => "",
          }
        }
      }
      subject.save(validate: false)
      expect(subject.children.map(&:name))
        .to eq []
    end
  end
end

