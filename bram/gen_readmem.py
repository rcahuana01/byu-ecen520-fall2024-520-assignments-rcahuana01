# Let's start by converting the message into its ASCII values, each represented as 8-bit binary.
message = """Rise all loyal Cougars and hurl your challenge to the foe.
You will fight, day or night, rain or snow.
Loyal, strong, and true
Wear the white and blue.
While we sing, get set to spring.
Come on Cougars it's up to you. Oh!

Chorus:
Rise and shout, the Cougars are out
along the trail to fame and glory.
Rise and shout, our cheers will ring out
As you unfold your victr'y story.

On you go to vanquish the foe for Alma Mater's sons and daughters.
As we join in song, in praise of you, our faith is strong.
We'll raise our colors high in the blue
And cheer our Cougars of BYU."""

# Convert the message into ASCII values (8-bit binary)
binary_data = [f"{ord(char):08b}" for char in message]

# Save this data in a format that Verilog readmemh function can use (hexadecimal values per line)
hex_data = [f"{ord(char):02x}" for char in message]

# Creating a file to store the hex values with newlines after each
file_path = "/mnt/data/verilog_mem_file.txt"
with open(file_path, 'w') as file:
    for hex_value in hex_data:
        file.write(hex_value + '\n')

file_path
