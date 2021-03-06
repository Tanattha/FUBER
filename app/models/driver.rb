class Driver < ActiveRecord::Base
    belongs_to :user
    has_many :trips
    has_many :passengers, :through => :trips
    has_many :reviews, as: :reviewable

    attr_accessor :leg, :driving_instructions

    def dashboard
        '/driver/dashboard'
    end

    def add_review(trip_id,comment,stars=0)
        stars = stars.to_i
        trip = Trip.find(trip_id)

        return nil if !stars.between? 0,5

        driver_review = self.reviews.create(comment: comment, stars: stars)
        trip.reviews << driver_review
        driver_review
    end

    def find_my_trip(id)
        self.trips.detect{|trip| trip.id == id.to_i }
    end

    def reviewed?(trip)
        trip.reviews.any?{|review| review.reviewable == self }
    end

    def rating 
        stars = passenger_reviews.map{|r| r.stars}
        total = stars.reduce{|star,sum| star + sum }
        if total
            avg = (total.to_f / stars.size).ceil(2)
        else
            5
        end
    end

    def passenger_reviews 
        self.trips.map{|trip| trip.reviews.select{|review| review.reviewable == trip.passenger }}.flatten
    end

    def self.closest_drivers(passenger_location)
        five_miles = 26411 #apporximate number of ft in 5 miles
        active_drivers = self.all.select {|driver| driver.is_available? }
        closest_drivers = active_drivers.select {|driver| driver.distance_from(passenger_location) }
        closest_drivers.sort_by { |driver| driver.leg[:ft]}
    end

    def is_available?
        self.trips.all?{|trip| trip.status.downcase == "canceled" || trip.status.downcase == "completed" || trip.status.downcase == "pending"}
    end

    def current_trip
        self.trips.detect{|trip| trip.status.downcase == "in route" || trip.status.downcase == "arrived"}
    end

    def active_trip
        self.trips.find{|trip| trip.status.downcase == "in route"}
    end


    def distance_from(passenger_location)
        
        trip = GMAPS.directions(self.current_location,passenger_location,mode: 'driving',alternatives: false)
        
        distance = trip[0][:legs][0][:distance][:text]
        num = distance.gsub(/[A-Za-z\s]/,"").to_f
        measurement = distance.scan(/([A-Za-z])/).join

        calc = {"ft"=> num,"mi"=> num * 5280} #converts everthing to feet

        @driving_instructions = trip[0][:legs][0][:steps].map.with_index(1) {|step,i| "#{i}. #{step[:html_instructions]}" }
        
        @leg = {
            ft: calc[measurement], 
            unit: measurement,
            time: trip[0][:legs][0][:duration][:text] ,
            geocode: trip[0][:legs][0][:start_location].to_json
        } 

    end

    def current_location
        address.sample
    end

    def address
        @addresses = [
            "1662 NY-300 #123, Newburgh, NY 12550","29-31 Garrisons Landing, Garrison, NY 10524",
            "2107 New South Post Rd, Highland Falls, NY 10928","127 Warren Landing Rd, Garrison, NY 10524",
            "26 E Main St, Pawling, NY 12564","142 Lakeside Dr, Pawling, NY 12564",
            "145 Main St, New Paltz, NY 12561","250 Main St, New Paltz, NY 12561",
            "679 Riverside Dr, New York, NY 10031","1 E 161 St, The Bronx, NY 10451",
            "945 Madison Ave, New York, NY 10021","62 Chelsea Piers, New York, NY 10011",
            "981 West Side Ave, Jersey City, NJ 07306","501 Jersey Ave, Jersey City, NJ 07302",
            "241-A Rockaway Pkwy, Brooklyn, NY 11212","1631-43 Pitkin Ave, Brooklyn, NY 11212",
            "7100 Shore Rd, Brooklyn, NY 11209","130 W Kingsbridge Rd, The Bronx, NY 10468",
            "5520 Broadway, The Bronx, NY 10463","5701 Arlington Ave, The Bronx, NY 10471",
            "5701 Arlington Ave, The Bronx, NY 10471","1200 Nepperhan Ave, Yonkers, NY 10703",
            "5 Barker Ave, White Plains, NY 10601","540 Saw Mill River Rd, Elmsford, NY 10523"
        ]
    end


end
