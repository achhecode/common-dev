
In `pom.xml` add the below dependencies in **project** > **dependencies**

```xml
<!-- https://mvnrepository.com/artifact/org.mapstruct/mapstruct -->  
<dependency>  
    <groupId>org.mapstruct</groupId>  
    <artifactId>mapstruct</artifactId>  
    <version>1.6.3</version>  
</dependency>  
  
<!-- https://mvnrepository.com/artifact/org.mapstruct/mapstruct-processor -->  
<dependency>  
    <groupId>org.mapstruct</groupId>  
    <artifactId>mapstruct-processor</artifactId>  
    <version>1.6.3</version>  
    <scope>provided</scope>  
</dependency>
```


In `pom.xml` add below path in **build** > **plugins** > **configuration** > **annotationProcessorPaths**

```xml
<path>  
    <groupId>org.mapstruct</groupId>  
    <artifactId>mapstruct-processor</artifactId>  
    <version>1.6.3</version>  
</path>
```

---

Let's say I want to convert **TripEntity** to **TripDTO** or **TripDTO** to **TripEntity**


Entity:

```java
package com.ar.trip_service.entity;  
  
import com.ar.logistics_models.options.TripStatus;  
import jakarta.persistence.*;  
import lombok.AllArgsConstructor;  
import lombok.Builder;  
import lombok.Data;  
import lombok.NoArgsConstructor;  
  
import java.time.Instant;  
import java.time.LocalDate;  
import java.time.LocalDateTime;  
import java.util.List;  
  
@Entity  
@Table(name = "trips")  
@Data  
@Builder  
@NoArgsConstructor  
@AllArgsConstructor  
public class TripEntity {  
    @Id  
    @GeneratedValue(strategy = GenerationType.IDENTITY)  
    private Long id;  
    private String tripId;  
    private String bookingId;  
    private String vehicleId;  
    private String driverId;  
  
    @Enumerated(EnumType.STRING)  
    private TripStatus status;  
    private LocalDate eta;  
    private Instant timestamp;  
    private LocalDateTime createdAt;  
  
    @OneToMany(mappedBy = "trip", cascade = CascadeType.ALL)  
    private List<TripEventEntity> events;  
  
}
```

```java
package com.ar.trip_service.entity;  
  
import com.ar.logistics_models.options.EventType;  
import jakarta.persistence.*;  
import lombok.AllArgsConstructor;  
import lombok.Builder;  
import lombok.Data;  
import lombok.NoArgsConstructor;  
  
import java.math.BigDecimal;  
import java.time.Instant;  
  
@Entity  
@Table(name = "trip_events")  
@Data  
@Builder  
@NoArgsConstructor  
@AllArgsConstructor  
public class TripEventEntity {  
    @Id  
    @GeneratedValue(strategy = GenerationType.IDENTITY)  
    private Long id;  
  
    @ManyToOne  
    @JoinColumn(name = "trip_id")  
    private TripEntity trip;  
  
    @Enumerated(EnumType.STRING)  
    private EventType eventType;  
  
    private String location;  
  
    private String description;  
  
    private Instant timestamp;  
  
    private BigDecimal cost;  
}
```


DTO:

```java
package com.ar.logistics_models.dto;  
  
import com.ar.logistics_models.options.TripStatus;  
import lombok.AllArgsConstructor;  
import lombok.Builder;  
import lombok.Data;  
import lombok.NoArgsConstructor;  
  
import java.time.Instant;  
import java.time.LocalDate;  
import java.time.LocalDateTime;  
import java.util.List;  
  
@Data  
@AllArgsConstructor  
@NoArgsConstructor  
@Builder  
public class TripDTO {  
    private String tripId;  
    private String bookingId;  
    private String vehicleId;  
    private String driverId;  
    private TripStatus status;  
    private LocalDate eta;  
    private Instant timestamp;  
    private LocalDateTime createdAt;  
    private List<TripEventDTO> events;  
}
```


```java
package com.ar.logistics_models.dto;  
  
import com.ar.logistics_models.options.EventType;  
import lombok.AllArgsConstructor;  
import lombok.Builder;  
import lombok.Data;  
import lombok.NoArgsConstructor;  
  
import java.math.BigDecimal;  
import java.time.Instant;  
  
@Data  
@AllArgsConstructor  
@NoArgsConstructor  
@Builder  
public class TripEventDTO {  
    private String tripId;  
    private EventType eventType;  
    private String location;  
    private String description;  
    private Instant timestamp;  
    private BigDecimal cost;  
}
```

Create a Mapper interface which would look like below for this:

```java
package com.ar.trip_service.mapper;  
  
import com.ar.logistics_models.dto.TripDTO;  
import com.ar.logistics_models.dto.TripEventDTO;  
import com.ar.trip_service.entity.TripEntity;  
import com.ar.trip_service.entity.TripEventEntity;  
import org.mapstruct.*;  
  
import java.util.List;  
  
@Mapper(componentModel = "spring")  
public interface TripEntityDTOMapper {  
  
    TripDTO toDTO(TripEntity entity);  
    TripEntity toEntity(TripDTO dto);  
  
    TripEventDTO toDTO(TripEventEntity entity);  
    TripEventEntity toEntity(TripEventDTO dto);  
  
    List<TripEventDTO> toDTOs(List<TripEventEntity> entities);  
    List<TripEventEntity> toEntities(List<TripEventDTO> dtos);  
}
```

All the custom objects must be added in mapper like here:
1. **TripEventEntity** <> **TripEventDTO**
2. **List of TripEventDTO <> List of TripEventEntity

---


Do `mvn clean install`, and verify the mapper in `target/generated-sources/annotations/com/ar/trip_service/mapper/TripEntityDTOMapperImpl.java`


```java
package com.ar.trip_service.mapper;  
  
import com.ar.logistics_models.dto.TripDTO;  
import com.ar.logistics_models.dto.TripEventDTO;  
import com.ar.trip_service.entity.TripEntity;  
import com.ar.trip_service.entity.TripEventEntity;  
import java.util.ArrayList;  
import java.util.List;  
import javax.annotation.processing.Generated;  
import org.springframework.stereotype.Component;  
  
@Generated(  
    value = "org.mapstruct.ap.MappingProcessor",  
    date = "2025-07-26T11:52:53+0530",  
    comments = "version: 1.6.3, compiler: javac, environment: Java 24.0.1 (Amazon.com Inc.)"  
)  
@Component  
public class TripEntityDTOMapperImpl implements TripEntityDTOMapper {  
  
    @Override  
    public TripDTO toDTO(TripEntity entity) {  
        if ( entity == null ) {  
            return null;  
        }  
  
        TripDTO.TripDTOBuilder tripDTO = TripDTO.builder();  
  
        tripDTO.tripId( entity.getTripId() );  
        tripDTO.bookingId( entity.getBookingId() );  
        tripDTO.vehicleId( entity.getVehicleId() );  
        tripDTO.driverId( entity.getDriverId() );  
        tripDTO.status( entity.getStatus() );  
        tripDTO.eta( entity.getEta() );  
        tripDTO.timestamp( entity.getTimestamp() );  
        tripDTO.createdAt( entity.getCreatedAt() );  
        tripDTO.events( toDTOs( entity.getEvents() ) );  
  
        return tripDTO.build();  
    }  
  
    @Override  
    public TripEntity toEntity(TripDTO dto) {  
        if ( dto == null ) {  
            return null;  
        }  
  
        TripEntity.TripEntityBuilder tripEntity = TripEntity.builder();  
  
        tripEntity.tripId( dto.getTripId() );  
        tripEntity.bookingId( dto.getBookingId() );  
        tripEntity.vehicleId( dto.getVehicleId() );  
        tripEntity.driverId( dto.getDriverId() );  
        tripEntity.status( dto.getStatus() );  
        tripEntity.eta( dto.getEta() );  
        tripEntity.timestamp( dto.getTimestamp() );  
        tripEntity.createdAt( dto.getCreatedAt() );  
        tripEntity.events( toEntities( dto.getEvents() ) );  
  
        return tripEntity.build();  
    }  
  
    @Override  
    public TripEventDTO toDTO(TripEventEntity entity) {  
        if ( entity == null ) {  
            return null;  
        }  
  
        TripEventDTO.TripEventDTOBuilder tripEventDTO = TripEventDTO.builder();  
  
        tripEventDTO.eventType( entity.getEventType() );  
        tripEventDTO.location( entity.getLocation() );  
        tripEventDTO.description( entity.getDescription() );  
        tripEventDTO.timestamp( entity.getTimestamp() );  
        tripEventDTO.cost( entity.getCost() );  
  
        return tripEventDTO.build();  
    }  
  
    @Override  
    public TripEventEntity toEntity(TripEventDTO dto) {  
        if ( dto == null ) {  
            return null;  
        }  
  
        TripEventEntity.TripEventEntityBuilder tripEventEntity = TripEventEntity.builder();  
  
        tripEventEntity.eventType( dto.getEventType() );  
        tripEventEntity.location( dto.getLocation() );  
        tripEventEntity.description( dto.getDescription() );  
        tripEventEntity.timestamp( dto.getTimestamp() );  
        tripEventEntity.cost( dto.getCost() );  
  
        return tripEventEntity.build();  
    }  
  
    @Override  
    public List<TripEventDTO> toDTOs(List<TripEventEntity> entities) {  
        if ( entities == null ) {  
            return null;  
        }  
  
        List<TripEventDTO> list = new ArrayList<TripEventDTO>( entities.size() );  
        for ( TripEventEntity tripEventEntity : entities ) {  
            list.add( toDTO( tripEventEntity ) );  
        }  
  
        return list;  
    }  
  
    @Override  
    public List<TripEventEntity> toEntities(List<TripEventDTO> dtos) {  
        if ( dtos == null ) {  
            return null;  
        }  
  
        List<TripEventEntity> list = new ArrayList<TripEventEntity>( dtos.size() );  
        for ( TripEventDTO tripEventDTO : dtos ) {  
            list.add( toEntity( tripEventDTO ) );  
        }  
  
        return list;  
    }  
}
```


---

### Uses:

```java
@Override  
public TripDTO getTripById(Long id) {  
    TripEntity entity = tripRepository.findById(id)  
            .orElseThrow(() -> new RuntimeException("Trip not found with id " + id));  
    return tripEntityDTOMapper.toDTO(entity);  
}
```

---


#### We can also create our own mapper similarly if fields type and object aren't similar

```java
package com.ar.trip_service.mapper;  
  
import com.ar.logistics_models.dto.BookingDTO;  
import com.ar.trip_service.entity.TripEntity;  
  
import java.time.Instant;  
import java.time.LocalDate;  
import java.time.LocalDateTime;  
  
public class TripMapper {  
    public static TripEntity toEntity(BookingDTO bookingDTO) {  
        return TripEntity.builder()  
                .id(null) // generated in service  
                .tripId(null)  
                .bookingId(bookingDTO.getBookingId())  
                .vehicleId(null) // generated in service  
                .driverId(null) // generated in service  
                .status(null)  
                .eta(LocalDate.now().plusDays(7))  
                .timestamp(Instant.now())  
                .createdAt(LocalDateTime.now())  
                .events(null)  
                .build();  
    }  
//  Not needed  
//    public static BookingDTO toBookingDTO(TripEntity tripEntity) {  
//    }  
}
```

##### Uses:

```java
@Override  
@Transactional  
public TripDTO createTrip(BookingDTO bookingDTO) {  
    TripEntity entity = TripMapper.toEntity(bookingDTO);  
    entity.setTripId(HexIdGenerator.generateHexId());  
    entity.setVehicleId(HexIdGenerator.generateVehicleId());  
    entity.setDriverId(HexIdGenerator.generateDriverId());  
    entity.setStatus(TripStatus.IN_PROGRESS);  
    TripEntity saved = tripRepository.save(entity);  
    return tripEntityDTOMapper.toDTO(saved);  
}
```


### Happy Coding,
## A R
