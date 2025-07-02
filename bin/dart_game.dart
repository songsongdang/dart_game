import 'dart:io';
import 'dart:math';

// ====== 추상 클래스 ======
abstract class Unit {
  String name;
  int health;
  int attack;
  int defense;

  Unit(this.name, this.health, this.attack, this.defense);

  bool get isAlive => health > 0;

  void showStatus();
}

// ====== 캐릭터 클래스 ======
class Character extends Unit {
  bool itemUsed = false;
  int baseAttack;

  Character(super.name, super.health, super.attack, super.defense)
    : baseAttack = attack;

  void attackMonster(Monster monster) {
    int damage = max(0, attack - monster.defense);
    monster.health -= damage;
    print('$name의 공격! ${monster.name}에게 $damage 데미지');
  }

  void defend(int monsterDamage) {
    health += monsterDamage;
    print('$name가 방어! 몬스터가 입힌 데미지만큼 체력 $monsterDamage 회복');
  }

  void useItem() {
    if (!itemUsed) {
      attack *= 2;
      itemUsed = true;
      print('$name가 아이템을 사용! 이번 턴 공격력 2배');
    } else {
      print('이미 아이템을 사용했습니다.');
    }
  }

  void resetItem() {
    if (itemUsed) {
      attack = baseAttack;
      itemUsed = false;
    }
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  공격력:$attack  방어력:$defense');
  }
}

// ====== 몬스터 클래스 ======
class Monster extends Unit {
  int maxAttack;
  int turnCount = 0;

  Monster(String name, int health, this.maxAttack) : super(name, health, 0, 0);

  void setRandomAttack(int minDefense) {
    int range = maxAttack - minDefense + 1;
    if (range <= 0) {
      attack = minDefense;
    } else {
      attack = minDefense + Random().nextInt(range);
    }
  }

  void attackCharacter(Character character) {
    int damage = max(0, attack - character.defense);
    character.health -= damage;
    print('$name의 공격! ${character.name}에게 $damage 데미지');
  }

  void increaseDefense() {
    defense += 2;
    print('$name의 방어력이 증가했습니다! 현재 방어력: $defense');
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  공격력:$attack  방어력:$defense');
  }
}

// ====== 게임 클래스 ======
class Game {
  late List<Character> party; // 파티 리스트
  late Character currentCharacter; // 현재 전투 중인 캐릭터
  late List<Monster> monsters;
  int monstersDefeated = 0;
  String? gameResult; // "승리" 또는 "패배"

  void startGame() {
    print('==== 파티 RPG 게임을 시작합니다 ====');
    loadParty();
    loadMonsters();

    while (party.any((c) => c.isAlive) && monsters.isNotEmpty) {
      triggerRandomEvent();

      currentCharacter = getFirstAliveCharacter();
      Monster monster = getRandomMonster();
      print('\n=== 새로운 몬스터 등장! ===');
      monster.showStatus();

      // ignore: unused_local_variable
      int turn = 0;
      monster.turnCount = 0;

      while (currentCharacter.isAlive && monster.isAlive) {
        turn++;
        monster.turnCount++;
        print('\n--- 현재 상태 ---');
        showPartyStatus();
        monster.showStatus();

        int action = getAction();
        currentCharacter.resetItem();

        if (action == 1) {
          currentCharacter.attackMonster(monster);
        } else if (action == 2) {
          print('${currentCharacter.name}가 방어를 선택!');
        } else if (action == 3) {
          currentCharacter.useItem();
          currentCharacter.attackMonster(monster);
        } else if (action == 4) {
          if (party.where((c) => c.isAlive && c != currentCharacter).isEmpty) {
            print('교체할 수 있는 동료가 없습니다.');
            continue;
          }
          currentCharacter = chooseAlly();
          print('동료 ${currentCharacter.name}(으)로 교체되었습니다!');
          continue;
        }

        monster.setRandomAttack(currentCharacter.defense);

        if (monster.isAlive) {
          if (action == 2) {
            int damage = max(0, monster.attack - currentCharacter.defense);
            currentCharacter.defend(damage);
          } else {
            monster.attackCharacter(currentCharacter);
          }
        }

        if (monster.turnCount % 3 == 0) {
          monster.increaseDefense();
        }

        if (!currentCharacter.isAlive) {
          print('\n${currentCharacter.name}가 쓰러졌습니다!');
          if (party.any((c) => c.isAlive)) {
            print('동료로 교체합니다.');
            currentCharacter = chooseAlly();
          } else {
            print('파티 전원이 쓰러졌습니다. 게임 오버!');
            gameResult = "패배";
            saveResultAndExit();
            return;
          }
        }
        if (!monster.isAlive) {
          print('\n${monster.name}를 물리쳤습니다!');
          monstersDefeated++;
          monsters.remove(monster);

          if (monsters.isEmpty) {
            print('\n축하합니다! 모든 몬스터를 물리쳤습니다!');
            gameResult = "승리";
            saveResultAndExit();
            return;
          } else {
            if (!askNextBattle()) {
              print('게임을 종료합니다.');
              gameResult = "패배";
              saveResultAndExit();
              return;
            }
            break;
          }
        }
      }
    }
  }

  void triggerRandomEvent() {
    print('\n[이벤트 발생]');
    Character target = getFirstAliveCharacter();
    final rand = Random().nextDouble();
    if (rand < 0.25) {
      int heal = 10 + Random().nextInt(11);
      target.health += heal;
      print('회복의 샘을 발견! ${target.name}의 체력이 $heal 회복되었습니다.');
    } else if (rand < 0.45) {
      int damage = 5 + Random().nextInt(6);
      target.health -= damage;
      print('함정에 빠졌습니다! ${target.name}의 체력이 $damage 감소했습니다.');
      if (target.health <= 0) {
        target.health = 0;
        print('${target.name}가 쓰러졌습니다...');
      }
    } else if (rand < 0.65) {
      int rewardType = Random().nextInt(2);
      if (rewardType == 0) {
        target.attack += 2;
        print('신비한 상자를 열어 ${target.name}의 공격력이 2 상승했습니다!');
      } else {
        target.defense += 2;
        print('신비한 상자를 열어 ${target.name}의 방어력이 2 상승했습니다!');
      }
    } else if (rand < 0.80) {
      print('수상한 상인을 만났습니다. 아이템(공격력 2배, 1회용)을 5 체력과 교환하시겠습니까? (y/n)');
      String? input = stdin.readLineSync();
      if (input != null && input.toLowerCase() == 'y') {
        if (target.health > 5) {
          target.health -= 5;
          target.itemUsed = false;
          print('아이템을 획득했습니다! (이번 전투 중 한 번 사용 가능)');
        } else {
          print('체력이 부족하여 거래할 수 없습니다.');
        }
      } else {
        print('상인을 무시하고 지나갑니다.');
      }
    } else {
      int heal = 5 + Random().nextInt(6);
      target.health += heal;
      print('잠시 휴식을 취해 ${target.name}의 체력이 $heal 회복되었습니다.');
    }
  }

  void showPartyStatus() {
    print('--- 파티 상태 ---');
    for (var c in party) {
      c.showStatus();
    }
    print('현재 전투 중: ${currentCharacter.name}');
  }

  Character getFirstAliveCharacter() {
    return party.firstWhere((c) => c.isAlive);
  }

  Character chooseAlly() {
    List<Character> aliveAllies = party
        .where((c) => c.isAlive && c != currentCharacter)
        .toList();
    print('교체할 동료를 선택하세요:');
    for (int i = 0; i < aliveAllies.length; i++) {
      print('${i + 1}. ${aliveAllies[i].name}');
    }
    while (true) {
      stdout.write('번호 입력 > ');
      String? input = stdin.readLineSync();
      if (input != null) {
        int? idx = int.tryParse(input);
        if (idx != null && idx >= 1 && idx <= aliveAllies.length) {
          return aliveAllies[idx - 1];
        }
      }
      print('잘못된 입력입니다.');
    }
  }

  void loadParty() {
    party = [];
    print('파티원을 2~3명까지 생성합니다.');
    int num = 0;
    while (num < 2 || num > 3) {
      stdout.write('파티원 수를 입력하세요(2~3): ');
      String? input = stdin.readLineSync();
      if (input != null) {
        num = int.tryParse(input) ?? 0;
      }
    }
    for (int i = 0; i < num; i++) {
      print('\n${i + 1}번째 파티원 정보를 입력합니다.');
      String name = getCharacterName();
      int health = getStat('체력');
      int attack = getStat('공격력');
      int defense = getStat('방어력');
      party.add(Character(name, health, attack, defense));
    }
  }

  int getStat(String statName) {
    while (true) {
      stdout.write('$statName을 입력하세요: ');
      String? input = stdin.readLineSync();
      if (input != null) {
        int? value = int.tryParse(input);
        if (value != null && value > 0) {
          return value;
        }
      }
      print('잘못된 입력입니다.');
    }
  }

  void loadMonsters() {
    try {
      final file = File('monsters.txt');
      final lines = file.readAsLinesSync();
      monsters = [];
      for (final line in lines) {
        final parts = line.trim().split(',');
        if (parts.length != 3) continue;
        int maxAttack = int.parse(parts[2]);
        if (maxAttack <= 0) {
          print('⚠️ 잘못된 몬스터 데이터: ${parts[0]}의 공격력이 0 이하입니다.');
          continue;
        }
        monsters.add(Monster(parts[0], int.parse(parts[1]), maxAttack));
      }
      if (monsters.isEmpty) throw FormatException('No monsters loaded');
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  Monster getRandomMonster() {
    return monsters[Random().nextInt(monsters.length)];
  }

  int getAction() {
    while (true) {
      stdout.write('행동 선택: 공격(1), 방어(2), 아이템(3), 동료교체(4) > ');
      String? input = stdin.readLineSync();
      if (input == '1' || input == '2' || input == '3' || input == '4') {
        return int.parse(input!);
      }
      print('잘못된 입력입니다. 1~4 중 하나를 입력하세요.');
    }
  }

  String getCharacterName() {
    while (true) {
      stdout.write('캐릭터 이름을 입력하세요(한글/영문만): ');
      String? name = stdin.readLineSync();
      if (name != null &&
          name.isNotEmpty &&
          RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
        return name;
      }
      print('이름은 한글/영문만 가능합니다.');
    }
  }

  bool askNextBattle() {
    while (true) {
      stdout.write('다음 몬스터와 대결하시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input.toLowerCase() == 'y') return true;
      if (input.toLowerCase() == 'n') return false;
      print('y 또는 n만 입력하세요.');
    }
  }

  void saveResultAndExit() {
    while (true) {
      stdout.write('결과를 저장하시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input.toLowerCase() == 'y') {
        try {
          final file = File('result.txt');
          for (var c in party) {
            file.writeAsStringSync(
              '${c.name},${c.health},$gameResult\n',
              mode: FileMode.append,
            );
          }
          print('결과가 저장되었습니다.');
        } catch (e) {
          print('결과 저장에 실패했습니다: $e');
        }
        break;
      } else if (input.toLowerCase() == 'n') {
        print('결과를 저장하지 않습니다.');
        break;
      } else {
        print('y 또는 n만 입력하세요.');
      }
    }
    print('게임을 종료합니다.');
    exit(0);
  }
}

void main() {
  Game game = Game();
  game.startGame();
}
