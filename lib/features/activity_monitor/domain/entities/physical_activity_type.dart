enum PhysicalActivityType {
  stationary,
  walking,
  running,
}

extension PhysicalActivityTypeX on PhysicalActivityType {
  String get displayName {
    switch (this) {
      case PhysicalActivityType.stationary:
        return 'Quieto';
      case PhysicalActivityType.walking:
        return 'Caminando';
      case PhysicalActivityType.running:
        return 'Corriendo';
    }
  }

  String get firstAnnouncement {
    switch (this) {
      case PhysicalActivityType.stationary:
        return 'Has dejado de moverte';
      case PhysicalActivityType.walking:
        return 'Estás caminando';
      case PhysicalActivityType.running:
        return 'Estás corriendo';
    }
  }

  String get changeAnnouncement {
    switch (this) {
      case PhysicalActivityType.stationary:
        return 'Te detuviste';
      case PhysicalActivityType.walking:
        return 'Cambiaste a caminata';
      case PhysicalActivityType.running:
        return 'Cambiaste a carrera';
    }
  }
}
