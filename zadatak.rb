require "google_drive"
session = GoogleDrive::Session.from_config("config.json")

class ReadSpreadsheet 
    include Enumerable
    attr_reader (:worksheet), (:matrix_col)
    def initialize(key, session)
        #key je sifra stranice tj speadsheet
        #prvi worksheet, predstavljeni su u nizovima, znaci 0 je prvi worksheet, 1 je drugi, ...
        @worksheet = session.spreadsheet_by_key(key).worksheets[0]
    end

    #Makes worksheet into matrix
    def worksheet_to_matrix(worksheet)
        #Ide kroz svaku kolonu, .map znaci da vraca niz tj niz nizova
        #unutrasnji 1.. isto to radi samo sto dobija red u koloni i vraca taj niz preko .map, samo iz nekog razloga [row, col] je transponovano
        matrix = (1..worksheet.num_cols).map do |col|
            (1..worksheet.num_rows).map { |row| worksheet[row, col] }
        end

        matrix = matrix.transpose #matrica je po kolonama a ja zelim sad redove da izbacim pa je transponujem 
        #prolazi red po red i obrise svaki red koji sadrzi element total ili subtotal
        matrix.delete_if { |row| (row.to_s.downcase.include? 'total') || (row.to_s.downcase.include? 'subtotal')}
        matrix = matrix.transpose

        @matrix_col = matrix # ima vertikanli niz
        #@matrix = matrix.transpose # normalna matrica
    end

    #Returns specific row with index i
    def row(i)
        matrix_col.transpose[i]
    end

    #Override each to go through whole matrix
    def each
        @matrix_col.each do |col|
            col.each do |row| 
                yield row
            end
        end
    end

    #Override how get index works [name]
    def [](name)
        #.delete(" ") ukloni space izmedju reci
        #.downcase stavi sve da budu mala slova
        #pp matrix_col
        #pp matrix_col.find { |col| col[0] == name}
        matrix_col.each do |col|
            return OtherBrackets.new(col, matrix_col) if col[0].delete(" ").downcase == name.delete(" ").downcase
        end
        
        #da ne bi vratilo celu matricu jer each voli to da radi
        nil
    end

    #name creates method
    def method_missing(key, *args)
        #ili je prosao proveru da nema argumente, vec je simbol pa ne mora da se menja
        #ili raise je exception u rubiju i poziva se ovde jedino ako nije args prazan
        args.empty? ? self[key.to_s] : (raise "can't have any arguments")
    end
end 

class OtherBrackets
    include Enumerable
    attr_reader (:col), (:matrix_col)
    def initialize(col, matrix_col)
        @col = col
        @matrix_col = matrix_col
    end

    #so [][] can work
    def [](index)
        @col[index]
    end

    def sum
        #uzme svaki red u koloni i pretvori ga u int, ako je rec bice vrednost 0
        s = 0
        col.each { |row| s += row.to_i }
        s
    end

    def avg
        #pozove sum i podeli sa velicinom niza bez header-a
        sum/(col.size - 1).to_f
    end

    #Override setter for new value if using [][index] = value
    def []=(index, value)
        @col[index] = value.to_s #this [] is from array class so it works normaly
    end

    #Override to string to return only column if [] is not called
    def to_s
        @col.to_s
    end

    #name creates method
    def method_missing(key, *args)
        #raise je exception u rubiju i poziva se ovde jedino ako nije args prazan
        #ovo se ne desava ako je ono posle unless true, args.empty? vraca true ako nema stvari u sebi
        raise "can't have any arguments" unless args.empty?

        #Prosao je proveru da nema argumente, vec je simbol pa ne mora da se menja

        key = key.to_s
        i = 0
        col.each_with_index do |num, index|
            if num == key
                i = index 
            end
        end

        matrix_col.transpose[i]
    end

    #Slucajevi kada ne sme da udje u missing, vraca true ako su razliciti, :to_ary je kao da ne postoji
    #Znaci ovo je provera da li da pozove method_missing, ako je key == :to_ary onda ne treba da zove
    #jer puts pokusava to_ary metodu da zove koja nije definisana a ja ne zelim uopste nju da pravi, i onda sledece sto poziva nakon sto to_ary nije uspeo je to_s 
    #Moro sam da dodam jer se to_s nece zvati i mora da postoji i drugi argument, to metoda zahteva
    def respond_to_missing?(key, *args)
        key != :to_ary
    end

    #Koristi ga map za taj niz da mu daje svaki broj u njemu
    def each
        col.each do |num|
            yield num
        end
    end
end

a = ReadSpreadsheet.new("1QCRHskb0Q4iEcA84q4zy_uatPwblKePapbYRE3BBjyA", session);

a.worksheet_to_matrix(a.worksheet)

p a.matrix_col
#p a.matrix_col.transpose
# p a.row(1)

# a.each do |item|
#    p item
# end

#puts a["Prva Kolona"] #p ignorise to string tako da mora puts da se koristi

# puts "valjda", a["Prva Kolona"][3]

#a["Prva Kolona"][2] = 2556
a["Prva Kolona"][3] = "heloo"

puts a["Prva Kolona"]

puts "opet istoooo", a.prvaKolona

puts " ", a.prvaKolona.sum
puts " ", a.prvaKolona.avg

puts " ", a.prvaKolona.heloo

puts " ", a.prvaKolona.map {|x| x = x.to_i + 1} #sve povecava za 1, ako je string on je 0
puts " ", a.prvaKolona.select { |x|  x.to_i.even?} #uzima sve koje su parne
puts " ", a.prvaKolona.reduce(:+) #sabira brojeve ali ako su stringovi onda ih konkanteria, ovo je od profesora uzeto


#instace_eval pravi funkciju za jednu klasu
#class_eval pravi funckiju za sve klase
