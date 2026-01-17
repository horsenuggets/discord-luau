--[[

EmbedTest

Tests for the Embed builder class.

--]]

local Embed = require("@discordluau/Structures/Embed")

return function()
    describe("Embed.new", function()
        it("should create an empty embed", function()
            local embed = Embed.new()
            expect(embed._data).to.be.a("table")
        end)

        it("should accept initial data", function()
            local embed = Embed.new({ title = "Test" })
            expect(embed._data.title).to.equal("Test")
        end)
    end)

    describe("SetTitle", function()
        it("should set the title", function()
            local embed = Embed.new():SetTitle("Hello")
            expect(embed._data.title).to.equal("Hello")
        end)

        it("should return self for chaining", function()
            local embed = Embed.new()
            local result = embed:SetTitle("Test")
            expect(result).to.equal(embed)
        end)
    end)

    describe("SetDescription", function()
        it("should set the description", function()
            local embed = Embed.new():SetDescription("World")
            expect(embed._data.description).to.equal("World")
        end)
    end)

    describe("SetColor", function()
        it("should set color from number", function()
            local embed = Embed.new():SetColor(0xFF0000)
            expect(embed._data.color).to.equal(0xFF0000)
        end)
    end)

    describe("SetColorHex", function()
        it("should set color from hex string", function()
            local embed = Embed.new():SetColorHex("#FF0000")
            expect(embed._data.color).to.equal(0xFF0000)
        end)

        it("should handle hex without hash", function()
            local embed = Embed.new():SetColorHex("00FF00")
            expect(embed._data.color).to.equal(0x00FF00)
        end)
    end)

    describe("SetFooter", function()
        it("should set footer text", function()
            local embed = Embed.new():SetFooter("Footer text")
            expect(embed._data.footer.text).to.equal("Footer text")
        end)

        it("should set footer with icon", function()
            local embed = Embed.new():SetFooter("Footer", "https://example.com/icon.png")
            expect(embed._data.footer.text).to.equal("Footer")
            expect(embed._data.footer.icon_url).to.equal("https://example.com/icon.png")
        end)
    end)

    describe("SetImage", function()
        it("should set image url", function()
            local embed = Embed.new():SetImage("https://example.com/image.png")
            expect(embed._data.image.url).to.equal("https://example.com/image.png")
        end)
    end)

    describe("SetThumbnail", function()
        it("should set thumbnail url", function()
            local embed = Embed.new():SetThumbnail("https://example.com/thumb.png")
            expect(embed._data.thumbnail.url).to.equal("https://example.com/thumb.png")
        end)
    end)

    describe("SetAuthor", function()
        it("should set author name", function()
            local embed = Embed.new():SetAuthor("AuthorName")
            expect(embed._data.author.name).to.equal("AuthorName")
        end)

        it("should set author with options", function()
            local embed = Embed.new():SetAuthor("Author", {
                url = "https://example.com",
                icon_url = "https://example.com/icon.png",
            })
            expect(embed._data.author.name).to.equal("Author")
            expect(embed._data.author.url).to.equal("https://example.com")
            expect(embed._data.author.icon_url).to.equal("https://example.com/icon.png")
        end)
    end)

    describe("AddField", function()
        it("should add a field", function()
            local embed = Embed.new():AddField("Name", "Value")
            expect(#embed._data.fields).to.equal(1)
            expect(embed._data.fields[1].name).to.equal("Name")
            expect(embed._data.fields[1].value).to.equal("Value")
        end)

        it("should add multiple fields", function()
            local embed = Embed.new():AddField("Field1", "Value1"):AddField("Field2", "Value2")
            expect(#embed._data.fields).to.equal(2)
        end)

        it("should set inline", function()
            local embed = Embed.new():AddField("Name", "Value", true)
            expect(embed._data.fields[1].inline).to.equal(true)
        end)
    end)

    describe("SetFields", function()
        it("should replace all fields", function()
            local embed = Embed.new():AddField("Old", "Field"):SetFields({
                { name = "New1", value = "Field1" },
                { name = "New2", value = "Field2" },
            })
            expect(#embed._data.fields).to.equal(2)
            expect(embed._data.fields[1].name).to.equal("New1")
        end)
    end)

    describe("ClearFields", function()
        it("should remove all fields", function()
            local embed = Embed.new():AddField("Name", "Value"):ClearFields()
            expect(#embed._data.fields).to.equal(0)
        end)
    end)

    describe("SetTimestamp", function()
        it("should set timestamp from string", function()
            local embed = Embed.new():SetTimestamp("2024-01-01T00:00:00.000Z")
            expect(embed._data.timestamp).to.equal("2024-01-01T00:00:00.000Z")
        end)

        it("should set current timestamp when no argument", function()
            local embed = Embed.new():SetTimestamp()
            expect(embed._data.timestamp).to.be.a("string")
        end)
    end)

    describe("SetUrl", function()
        it("should set url", function()
            local embed = Embed.new():SetUrl("https://example.com")
            expect(embed._data.url).to.equal("https://example.com")
        end)
    end)

    describe("ToJSON", function()
        it("should return the data table", function()
            local embed = Embed.new():SetTitle("Test")
            local json = embed:ToJSON()
            expect(json.title).to.equal("Test")
        end)
    end)

    describe("GetLength", function()
        it("should calculate total character length", function()
            local embed = Embed.new()
                :SetTitle("12345")
                :SetDescription("1234567890")
                :SetFooter("123")
                :SetAuthor("12")
                :AddField("1", "12")
            expect(embed:GetLength()).to.equal(23)
        end)
    end)

    describe("chaining", function()
        it("should support full method chaining", function()
            local embed = Embed.new()
                :SetTitle("Title")
                :SetDescription("Description")
                :SetColor(0xFF0000)
                :SetFooter("Footer")
                :SetAuthor("Author")
                :AddField("Field1", "Value1")
                :AddField("Field2", "Value2", true)

            expect(embed._data.title).to.equal("Title")
            expect(embed._data.description).to.equal("Description")
            expect(embed._data.color).to.equal(0xFF0000)
            expect(embed._data.footer.text).to.equal("Footer")
            expect(embed._data.author.name).to.equal("Author")
            expect(#embed._data.fields).to.equal(2)
        end)
    end)
end
